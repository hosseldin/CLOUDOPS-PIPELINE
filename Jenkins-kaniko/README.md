# 🚀 Jenkins + Kaniko + Trivy + SonarQube CI/CD Pipeline

A production-grade Jenkins pipeline that builds Docker images using **Kaniko**, scans them for vulnerabilities with **Trivy**, runs **SonarQube** static code analysis, and pushes them securely to **Amazon ECR** — all within a **Kubernetes Pod** agent.

---

## 📋 Overview

This CI/CD pipeline enables:

* Building Docker images without privileged access using **Kaniko**
* Scanning the image before pushing using **Trivy**
* Performing static code analysis using **SonarQube**
* Securely pushing trusted images to **AWS ECR**
* Triggering via GitHub push
* Slack notifications on pipeline success

---

## ⚙️ Tech Stack

* Jenkins with Kubernetes plugin
* Kaniko (Image building)
* Trivy (Vulnerability scanning)
* SonarQube (Static code analysis)
* Amazon ECR (Image registry)
* Slack (Notifications)
* GitHub (Source control)

---

## 🔧 Prerequisites

* AWS account with IAM permissions
* ECR repository
* Kubernetes cluster with Jenkins installed
* Jenkins Kubernetes plugin installed
* SonarQube instance (can be cloud or self-hosted)
* GitHub repository to trigger pipeline

---

## 🔐 Step 1: Create IAM Policy and Kubernetes Service Account

We need to create an IAM policy and bind it to a Kubernetes service account that Jenkins will use when building and pushing images.

### IAM Policy (`jenkins-ecr-policy.json`)

```json
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
```

### Create the Policy and Service Account

```bash
aws iam create-policy \
  --policy-name ECRPushPolicy \
  --policy-document file://jenkins-ecr-policy.json

eksctl create iamserviceaccount \
  --name kaniko-sa \
  --namespace jenkins-ns \
  --cluster eks-cluster \
  --attach-policy-arn arn:aws:iam::773893527461:policy/ECRPushPolicy \
  --approve \
  --override-existing-serviceaccounts
```

---

## 🚀 Deploying Jenkins with Helm

### 1. Install Jenkins

```bash
helm install jenkins jenkinsci/jenkins -n jenkins-ns
```

> Make sure the `jenkins-ns` namespace exists:
>
> ```bash
> kubectl create namespace jenkins-ns
> ```

### 2. Get Jenkins Admin Password

```bash
kubectl exec --namespace jenkins-ns -it svc/jenkins -c jenkins -- \
  cat /run/secrets/additional/chart-admin-password
```

### 3. Expose Jenkins

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jenkins-ingress
  namespace: jenkins-ns
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/group.name: itiproject-alb
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}, {"HTTPS":443}]'
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/healthcheck-port: "8080"
    alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=60
spec:
  ingressClassName: alb
  tls:
    - hosts:
        - jenkins.itiproject.site
  rules:
    - host: jenkins.itiproject.site
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: jenkins
                port:
                  number: 8080
```

---

## 🛠️ Pipeline Breakdown

This CI/CD pipeline consists of the following steps:

1. **Checkout Code**
   Clones the GitHub repository.

2. **Static Code Analysis with SonarQube**
   Runs static analysis on the Docker image using SonarQube.

3. **Build with Kaniko (No Push)**
   Builds the Docker image without pushing it yet, using Kaniko.

4. **Scan with Trivy**
   Scans the built image for security vulnerabilities.

5. **Push Verified Image to ECR**
   If the image passes the vulnerability scan and static analysis, it is pushed to AWS ECR.

6. **Notify via Slack**
   Sends a notification to Slack with the status of the pipeline.

---

## ❗ Example Trivy Scan Output

```
scanning image.tar...
cdist3-02002EA91L:
---------------------
CRITICAL: 1
HIGH: 2
```

---

## 🧠 Pipeline Summary in Plain English

1. **Pulls the latest code** from GitHub
2. **Runs static code analysis** using **SonarQube**
3. **Builds a Docker image** using **Kaniko** (no push yet)
4. **Scans the image** using **Trivy**
5. **Pushes to AWS ECR** only if the image is safe
6. **Notifies your team** via Slack

---

## 🧱 Pipeline Step Details

### 🧾 `agent { kubernetes { yaml '''...''' } }`

Runs the pipeline in a Kubernetes Pod with:

* **Kaniko container** for building
* **Trivy container** for scanning
* **SonarQube container** for static analysis
* Mounted volumes for AWS access and workspace

---

### 🌍 `environment { ... }`

Global variables:

* `AWS_REGION`
* `ECR_REGISTRY`
* `ECR_REPOSITORY`
* `TARGET_FOLDER`

---

### 🔔 `triggers { githubPush() }`

Starts the pipeline on every GitHub push.

---

### 🧩 `stage('Checkout')`

Clones the repo.

---

### 🧪 `stage('Static Code Analysis with SonarQube')`

Runs static code analysis on the code to detect bugs, vulnerabilities, and code smells.

---

### 🧪 `stage('Build with Kaniko + Prepare Trivy Scan (No Push)')`

Builds the image as `.tar` without pushing it to ECR.

---

### 🔍 `stage('Scan with Trivy')`

Scans the tarball and reports vulnerabilities.

---

### 🚀 `stage('Push Verified Image to ECR')`

Pushes the image to ECR if the image is clean and secure.

---

### 📣 `stage('Notify Slack')`

Sends the pipeline status and metadata to Slack.

---

## ✅ Why Use This Pipeline?

* 🔐 **Secure**: No Docker-in-Docker or root access
* 🤖 **Automated**: CI/CD from push to deployment
* ☁️ **Cloud-Native**: Runs fully inside Kubernetes
* 📣 **Collaborative**: Informs your team with Slack alerts
* 🔍 **Quality Assurance**: Static code analysis with **SonarQube** to identify issues early
* 🛡️ **Security Focused**: Image vulnerability scanning with **Trivy**


