# 🚀 Jenkins + Kaniko + Trivy CI/CD Pipeline

A production-grade Jenkins pipeline that builds Docker images using **Kaniko**, scans them for vulnerabilities with **Trivy**, and pushes them securely to **Amazon ECR** — all within a **Kubernetes Pod** agent.

---

## 📋 Overview
This CI/CD pipeline enables:
- Building Docker images without privileged access using **Kaniko**
- Scanning the image before pushing using **Trivy**
- Securely pushing trusted images to **AWS ECR**
- Triggering via GitHub push
- Slack notifications on pipeline success

---

## ⚙️ Tech Stack
- Jenkins with Kubernetes plugin
- Kaniko (Image building)
- Trivy (Vulnerability scanning)
- Amazon ECR (Image registry)
- Slack (Notifications)
- GitHub (Source control)

---

## 🔧 Prerequisites
- AWS account with IAM permissions
- ECR repository
- Kubernetes cluster with Jenkins installed
- Jenkins Kubernetes plugin installed

---

## 🔐 Step 1: IAM Policy and User Setup

**IAM/jenkins-ecr-policy.json**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    }
  ]
}
```

**Create User and Attach Policy**
```bash
aws iam create-user --user-name jenkins-ecr
aws iam create-policy --policy-name jenkins-ecr-policy --policy-document file://jenkins-ecr-policy.json
aws iam attach-user-policy \
    --user-name jenkins-ecr \
    --policy-arn arn:aws:iam::<YOUR_ACCOUNT_ID>:policy/jenkins-ecr-policy
aws iam create-access-key --user-name jenkins-ecr
```

---

## 🗂️ Step 2: Create ECR Repository
```bash
aws ecr create-repository \
    --repository-name node-app-jenkins \
    --region us-east-1
```

---

## 🛡️ Step 3: Create AWS Secret in Kubernetes

**k8s/aws-secret.yaml**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: aws-credentials
  namespace: jenkins-ns
type: Opaque
data:
  AWS_ACCESS_KEY_ID: <base64-encoded-key>
  AWS_SECRET_ACCESS_KEY: <base64-encoded-secret>
```
> Encode values: `echo -n 'your_value' | base64`

```bash
kubectl apply -f k8s/aws-secret.yaml -n jenkins-ns
```

---

## 🛠️ Pipeline Breakdown

### 1. Agent Pod with Kaniko & Trivy
Defined using Kubernetes YAML within the Jenkinsfile. This ensures reproducible, isolated environments with necessary tools:
- **Kaniko**: For Docker-in-docker alternative builds
- **Trivy**: For image scanning
- Volumes mounted for workspace and AWS secrets

### 2. Stages

#### ✅ Checkout
- Pulls latest code from GitHub repository

#### 🏗️ Build with Kaniko (No Push)
- Uses `--no-push` & `--tarPath` to generate a local image tarball only
- Ensures scanning is done before pushing any image to a registry

#### 🔍 Scan with Trivy
- Scans tarred image with specified severities
- Uses `--exit-code 0` to avoid pipeline fail but gives insights

#### 📤 Push Verified Image to ECR
- Only happens after scanning
- Uses `--tarPath` and `--destination` to safely upload

#### 📣 Slack Notification
- On pipeline success, sends a formatted Slack message

---


---

## ❗ Example Trivy Scan Output
```
scanning image.tar...
cdist3-02002EA91L:
---------------------
CRITICAL: 1
HIGH: 2
```

