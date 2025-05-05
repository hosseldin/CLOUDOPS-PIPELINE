# 🚀 ArgoCD & Image Updater Setup Guide

This guide walks you through setting up **ArgoCD** for GitOps-based Kubernetes deployments and integrating **ArgoCD Image Updater** to automatically track and deploy updated images from **Amazon ECR**.

---

## 🛠️ Prerequisites

* A running **EKS cluster**
* **kubectl**, **eksctl**, **helm**, and **awscli** installed and configured
* An **ECR repository** with container images
* A **GitHub repository** containing your Helm or Kubernetes manifests

---

## 📦 Install ArgoCD

```bash
kubectl create namespace argocd

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd
```

---

## 🌐 Expose ArgoCD via ALB Ingress

> Example using AWS ALB Ingress Controller

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ingress
  namespace: argocd
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/healthcheck-port: "443"
    alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=60
    alb.ingress.kubernetes.io/group.name: itiproject-alb
spec:
  ingressClassName: alb
  tls:
    - hosts:
        - argocd.itiproject.site
  rules:
    - host: argocd.itiproject.site
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 443
```

---

## 🔐 Access ArgoCD

```bash
# Default Username
admin

# Retrieve Initial Password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

---

## 📂 Deploy a Sample Application

```bash
kubectl create namespace argoapp
```

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  destination:
    namespace: argoapp
    server: https://kubernetes.default.svc
  source:
    repoURL: https://github.com/mina-safwat-1/test_argo.git
    path: k8s
    targetRevision: HEAD
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

---

## 🌀 ArgoCD Image Updater Setup

### 🔧 1. Create IAM Service Account

```bash
eksctl create iamserviceaccount \
  --name argocd-image-updater \
  --namespace argocd \
  --cluster eks-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
  --approve \
  --override-existing-serviceaccounts
```

> To delete it later:

```bash
eksctl delete iamserviceaccount \
  --name argocd-image-updater \
  --namespace argocd \
  --cluster eks-cluster
```

---

### 📦 2. Install ArgoCD Image Updater

**Create `image-updater-values.yaml`:**

```yaml
config:
  registries:
    - name: ECR
      api_url: https://<account_id>.dkr.ecr.<region>.amazonaws.com
      prefix: "<account_id>.dkr.ecr.<region>.amazonaws.com"
      ping: yes
      default: true
      insecure: false
      credentials: ext:/scripts/ecr-login.sh
      credsexpire: 1h

authScripts:
  enabled: true
  scripts:
    ecr-login.sh: |
      #!/bin/sh
      export HOME=/tmp
      aws ecr --region "us-east-1" get-authorization-token --output text --query 'authorizationData[].authorizationToken' | base64 -d
```

**Install with Helm:**

```bash
helm upgrade --install argocd-image-updater argo/argocd-image-updater \
  --namespace argocd \
  -f image-updater-values.yaml \
  --set serviceAccount.name=argocd-image-updater \
  --set serviceAccount.create=false
```

**Check Logs:**

```bash
kubectl logs -n argocd deploy/argocd-image-updater
```

---

### 🔑 3. Configure Git Access

**Generate SSH Key:**

```bash
ssh-keygen -t rsa -b 4096 -C "argocd-image-updater"
```

* Add the **public key** to your GitHub repo → **Settings → Deploy Keys**
* Add the **private key** to Kubernetes:

```bash
kubectl -n argocd create secret generic git-creds \
  --from-file=sshPrivateKey=/home/ec2-user/.ssh/id_rsa
```

---

### 🏷️ 4. Annotate ArgoCD App for Image Updates

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
  annotations:
    argocd-image-updater.argoproj.io/image-list: my-image=773893527461.dkr.ecr.us-east-1.amazonaws.com/node-app-jenkins
    argocd-image-updater.argoproj.io/my-image.update-strategy: newest-build
    argocd-image-updater.argoproj.io/my-image.allow-tags: regexp:^v.*
    argocd-image-updater.argoproj.io/write-back-method: git:secret:argocd/git-creds
    argocd-image-updater.argoproj.io/write-back-target: helmvalues:/k8s/values.yaml
    argocd-image-updater.argoproj.io/my-image.helm.image-spec: image.tag
    argocd-image-updater.argoproj.io/git-repository: git@github.com:mina-safwat-1/test_argo.git
    argocd-image-updater.argoproj.io/git-branch: main
spec:
  destination:
    namespace: argoapp
    server: https://kubernetes.default.svc
  source:
    repoURL: https://github.com/mina-safwat-1/test_argo.git
    path: k8s
    targetRevision: HEAD
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - Validate=true
      - CreateNamespace=false
      - PrunePropagationPolicy=foreground
      - PruneLast=true
```

---

## ✅ Final Notes

* You should now have ArgoCD managing your applications, and the Image Updater will keep container images in sync with the latest available builds from Amazon ECR.
* Make sure your image tag strategy matches your CI/CD pipeline's output (e.g., tags starting with `v`).

---

Would you like a PDF version of this guide or a downloadable Markdown file?
