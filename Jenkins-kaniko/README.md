# 🚀 Jenkins + Kaniko + Trivy CI/CD Pipeline

A production-grade Jenkins pipeline that builds Docker images using **Kaniko**, scans them for vulnerabilities with **Trivy**, and pushes them securely to **Amazon ECR** — all within a **Kubernetes Pod** agent.


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

### 🚀 Deploying Jenkins with Helm

#### 1. **Prepare Values File**

Generate the default values file:

```bash
helm show values jenkinsci/jenkins > /tmp/jenkins.yml
```

Edit `/tmp/jenkins.yml`:

* Set `controller.serviceType` to `LoadBalancer`.
* Configure the `controller.ingress` section if you plan to use Ingress.

#### 2. **Install Jenkins**

```bash
helm install jenkins jenkinsci/jenkins --values /tmp/jenkins.yml -n jenkins-ns
```

> Make sure the `jenkins-ns` namespace exists, or create it using:
>
> ```bash
> kubectl create namespace jenkins-ns
> ```

#### 3. **Get Jenkins Admin Password**

```bash
kubectl exec --namespace jenkins-ns -it svc/jenkins -c jenkins -- \
  cat /run/secrets/additional/chart-admin-password
```

#### 4. **Get LoadBalancer IP**

```bash
kubectl get svc --namespace jenkins-ns jenkins
```

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


## ❗ Example Trivy Scan Output
```
scanning image.tar...
cdist3-02002EA91L:
---------------------
CRITICAL: 1
HIGH: 2
```


## 🧠 **Pipeline Summary in Plain English**

This Jenkins pipeline automates these steps:

1. **Checks the code from GitHub**.
2. **Builds a Docker image** *without pushing it* using **Kaniko**.
3. **Scans the image for security issues** using **Trivy**.
4. If the scan is okay, it **pushes the image to AWS ECR**.
5. Finally, it **sends a Slack notification**.

---

## 🧱 **Pipeline Explained Step by Step**

### 🧾 `agent { kubernetes { yaml '''...''' } }`
- This tells Jenkins to run the pipeline in a **Kubernetes pod**.
- The pod contains:
  - A **Kaniko container** to build Docker images.
  - A **Trivy container** to scan images for vulnerabilities.
- It mounts:
  - AWS credentials.
  - A shared workspace for both tools.

---

### 🌍 `environment { ... }`
- Defines global variables:
  - `AWS_REGION` – The AWS region (e.g., `us-east-1`)
  - `ECR_REGISTRY` – Your Amazon ECR registry URL.
  - `ECR_REPOSITORY` – The image repository name in ECR.
  - `TARGET_FOLDER` – The folder that has the Dockerfile and app code (`nodeapp`).

---

### 🔔 `triggers { githubPush() }`
- This triggers the pipeline automatically when you **push code to GitHub**.

---

### 🧩 `stage('Checkout')`
- Clones your GitHub repo into Jenkins workspace.

---

### 🧪 `stage('Build with Kaniko + Prepare Trivy Scan (No Push)')`
- Kaniko builds the Docker image from the Dockerfile.
- But **does NOT push** it yet.
- Instead, it saves the image locally as a `.tar` file so Trivy can scan it first.

---

### 🔍 `stage('Scan with Trivy')`
- Trivy scans the image `.tar` file for **vulnerabilities** (LOW to CRITICAL).
- If vulnerabilities are found, the build still passes (`--exit-code 0`), but you’ll see the issues.

> ✅ Tip: You can make it fail on vulnerabilities by changing `--exit-code 0` to `--exit-code 1`.

---

### 🚀 `stage('Push Verified Image to ECR')`
- If scan is successful, Kaniko pushes the verified image to your **Amazon ECR**.
- Uses Jenkins `BUILD_NUMBER` to tag the image (like `v12`, `v13`, etc.).

---

### 📣 `stage('Notify Slack')`
- Sends a nicely formatted Slack message to your channel `eks-jenkins-notifications`.
- Includes:
  - Build number
  - Job name
  - Status (success)
  - Duration
  - Who triggered the build
  - Commit ID
  - An image!

---

## ✅ Why This Pipeline is Good

- **Secure**: No need for Docker daemon or privileged access.
- **Automated**: Builds, scans, and deploys on every GitHub push.
- **Scalable**: Runs inside Kubernetes.
- **Transparent**: Notifies your team on Slack.





{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    }
  ]
}


aws iam create-policy \
  --policy-name ECRPushPolicy \
  --policy-document file://ecr-push-policy.json


eksctl create iamserviceaccount \
  --name kaniko-sa \
  --namespace jenkins-ns \
  --cluster eks-cluster \
  --attach-policy-arn arn:aws:iam::773893527461:policy/ECRPushPolicy \
  --approve \
  --override-existing-serviceaccounts



