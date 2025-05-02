
# 🐝 EKS Cluster Setup Guide

Provision your Amazon EKS cluster (via Terraform) and install key add‑ons: the AWS Load Balancer Controller and the EBS CSI Driver. Follow these steps **after** your Terraform apply has successfully created the cluster and node groups.

---

## 🔗 1️⃣ Connect `kubectl` to Your EKS Cluster

Fetch and merge the cluster’s kubeconfig so you can run `kubectl` commands against it:

```bash
aws eks update-kubeconfig \
  --name eks-cluster \
  --region us-east-1
````

---

## ☸️ 2️⃣ Install AWS Load Balancer Controller

The **AWS Load Balancer Controller** provisions and manages AWS ALBs/NLBs for your Kubernetes Ingress resources.

### 📥 a) Download the IAM Policy

```bash
curl -O \
  https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.12.0/docs/install/iam_policy.json
```

### 🛂 b) Create the IAM Policy

```bash
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json
```

### 🔗 c) Associate IAM OIDC Provider

```bash
eksctl utils associate-iam-oidc-provider \
  --region us-east-1 \
  --cluster eks-cluster \
  --approve
```

### 👤 d) Create IAM Service Account

Replace `<ACCOUNT_ID>` with your AWS Account ID:

```bash
eksctl create iamserviceaccount \
  --cluster eks-cluster \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --region us-east-1 \
  --approve
```

### 📦 e) Install via Helm

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### ✅ f) Verify Deployment

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
```

---

## 📀 3️⃣ Install EBS CSI Driver

The **EBS CSI Driver** enables dynamic provisioning of EBS volumes for your pods.

```bash
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster eks-cluster \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --region us-east-1 \
  --approve
```

> The above command creates an IAM service account with the **AmazonEBSCSIDriverPolicy** attached so the CSI driver can manage EBS volumes.

---

## 🎉 You’re All Set!

* ✅ **`kubectl get nodes`** should show your EKS worker nodes ready.
* ✅ **Ingress** resources will now automatically provision ALBs via the Load Balancer Controller.
* ✅ **PersistentVolumeClaims** with StorageClass `ebs-csi` will dynamically mount EBS volumes.

Enjoy your production‑ready EKS cluster! 🚀🌐🐝

```
