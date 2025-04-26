# Jenkins + Kaniko + ECR Pipeline Setup

This project demonstrates how to build and push Docker images using **Kaniko** in a **Kubernetes** environment with **Jenkins**, storing images in **Amazon ECR**.

---

## 🔧 Prerequisites
- AWS Account with permissions to manage IAM and ECR
- Kubernetes Cluster with Jenkins installed
- Jenkins Kubernetes plugin installed

---

## 📁 File Structure

```bash
project-root/
├── iam/
│   ├── create-policy.sh
│   ├── create-user.sh
├── k8s/
│   └── aws-secret.yaml
├── jenkins/
│   └── Jenkinsfile
└── README.md
```

---

## 🔐 Step 1: Create IAM Policy and User

**IAM/create-policy.sh**
```bash
aws iam create-policy \
    --policy-name jenkins-ecr-policy \
    --policy-document file://jenkins-ecr-policy.json
```

**IAM/create-user.sh**
```bash
aws iam create-user --user-name jenkins-ecr
aws iam attach-user-policy \
    --user-name jenkins-ecr \
    --policy-arn arn:aws:iam::<YOUR_ACCOUNT_ID>:policy/jenkins-ecr-policy
aws iam create-access-key --user-name jenkins-ecr
```

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

---

## 🗂️ Step 2: Create ECR Repository

```bash
aws ecr create-repository \
    --repository-name kanikotest \
    --region us-east-1
```

---

## 🔐 Step 3: Create AWS Credentials Secret in Kubernetes

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
> Encode using: `echo -n 'YOUR_VALUE' | base64`

Apply the secret:
```bash
kubectl apply -f k8s/aws-secret.yaml
```

---

## ⚙️ Jenkins Pipeline Configuration

**jenkins/Jenkinsfile**
```groovy
pipeline {
  agent {
    kubernetes {
      yamlFile 'jenkins/kaniko-pod.yaml'
    }
  }

  environment {
    AWS_REGION = 'us-east-1'
    ECR_REGISTRY = '214797541313.dkr.ecr.us-east-1.amazonaws.com'
    ECR_REPOSITORY = 'kanikotest'
  }

  stages {
    stage('Build & Push to ECR') {
      steps {
        container('kaniko') {
          script {
            sh '''
              mkdir -p /kaniko/.docker
              echo '{
                "credHelpers": {
                  "${ECR_REGISTRY}": "ecr-login"
                }
              }' > /kaniko/.docker/config.json

              /kaniko/executor \
                --context=git://github.com/hosseldin/CLOUDOPS-PIPELINE.git#refs/heads/main \
                --context-sub-path=nodeapp \
                --dockerfile=Dockerfile \
                --destination=${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}
            '''
          }
        }
      }
    }
  }
}
```

**jenkins/kaniko-pod.yaml**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kaniko
  namespace: jenkins-ns
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - /busybox/cat
    tty: true
    env:
    - name: AWS_ACCESS_KEY_ID
      valueFrom:
        secretKeyRef:
          name: aws-credentials
          key: AWS_ACCESS_KEY_ID
    - name: AWS_SECRET_ACCESS_KEY
      valueFrom:
        secretKeyRef:
          name: aws-credentials
          key: AWS_SECRET_ACCESS_KEY
    volumeMounts:
    - name: aws-config
      mountPath: /kaniko/.aws
  volumes:
  - name: aws-config
    secret:
      secretName: aws-credentials
```

---

## ✅ Result
Once triggered, Jenkins will:
1. Spin up a Kaniko pod in Kubernetes
2. Use AWS credentials from a secret
3. Build the Docker image from a Git repo
4. Push it to your ECR repository

---

## 📌 Tips
- Make sure your Jenkins has permissions to create dynamic pods
- Validate secret keys and base64 encoding
- You can test the Kaniko executor locally in a Docker container

---

## 📚 References
- [Kaniko Project](https://github.com/GoogleContainerTools/kaniko)
- [Amazon ECR Documentation](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html)
- [Jenkins Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)

---

## 🧑‍💻 Author
**Mohamed Mourad**
