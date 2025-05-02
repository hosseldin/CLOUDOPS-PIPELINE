

# 🚀 ArgoCD & Image Updater Setup Guide

This guide walks you through installing **ArgoCD** for GitOps-based deployments and **ArgoCD Image Updater** to automatically update container images from **Amazon ECR**.

---

## 🛥️ Install ArgoCD

```bash
kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd --namespace argocd
```

---

## 🌐 Expose ArgoCD via Ingress (ALB Example)

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
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/healthcheck-port: "443"
    alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=60
    alb.ingress.kubernetes.io/group.name: itiproject-alb
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/ssl-redirect: '443'
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

## 🔐 ArgoCD Default Login Credentials

```bash
# Username
admin

# Decode Initial Password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

---

## ⚙️ ArgoCD Application Deployment Example

```bash
kubectl create namespace argoapp
```

Minimal ArgoCD `Application`:

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

### 1️⃣ IAM Permissions

Ensure your worker nodes (or IRSA role if using EKS) have permissions to access ECR (e.g., `ecr:GetAuthorizationToken`, `ecr:BatchGetImage`, etc.).

---

### 2️⃣ Install ArgoCD Image Updater

Create `image-updater-values.yaml`:

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
      aws ecr --region "<region>" get-authorization-token \
        --output text --query 'authorizationData[].authorizationToken' | base64 -d
```

Install via Helm:

```bash
helm upgrade --install argocd-image-updater argo/argocd-image-updater \
  --namespace argocd -f image-updater-values.yaml
```

✅ Check Logs:

```bash
kubectl logs -n argocd deploy/argocd-image-updater
```

---

### 3️⃣ GitHub Deploy Key & Git Secret Setup

Generate SSH key:

```bash
ssh-keygen
```

* Add the **public key** to your GitHub repo under **Deploy Keys**.
* Add the **private key** to ArgoCD as a Kubernetes secret:

```bash
kubectl -n argocd create secret generic git-creds \
  --from-file=sshPrivateKey=/home/ec2-user/.ssh/id_rsa
```

---

### 4️⃣ Annotated ArgoCD Application with Image Updater

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
      allowEmpty: false
    syncOptions:
      - Validate=true
      - CreateNamespace=false
      - PrunePropagationPolicy=foreground
      - PruneLast=true
```

---
