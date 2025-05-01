# External Secrets Operator with AWS Secrets Manager

This guide explains how to set up the [External Secrets Operator](https://external-secrets.io) with **AWS Secrets Manager** to automatically sync secrets into your Kubernetes cluster.

---

##  Installation

**1️⃣ Add the Helm Repository:**

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
```

**2️⃣ Install the External Secrets Operator:**

```bash
helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets \
  --create-namespace \
  --set installCRDs=true
```

**3️⃣ Verify Installation:**

```bash
kubectl get pods -n external-secrets
```

---

## 🔐 Connect to AWS Secrets Manager

### 1️⃣ Create an IAM Policy for Secrets Access

🪸 Create a file named `sec.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecrets"
      ],
      "Resource": "*"
    }
  ]
}
```

👉 Create the IAM policy:

```bash
aws iam create-policy \
  --policy-name SecretsManagerReadPolicy \
  --policy-document file://sec.json
```

---

### 2️⃣ Create a Kubernetes Secret with AWS Credentials

```bash
kubectl create secret generic awssm-secret \
  -n external-secrets \
  --from-literal=access-key-id=<YOUR_ACCESS_KEY_ID> \
  --from-literal=secret-access-key=<YOUR_SECRET_ACCESS_KEY>
```

---

### 3️⃣ Create a ClusterSecretStore

🪸 Create a file named `cluster-secret-store.yaml`:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-cluster-secret-store
spec:
  provider:
    aws:
      service: SecretsManager
      region: <YOUR_AWS_REGION>
      auth:
        secretRef:
          accessKeyIDSecretRef:
            name: awssm-secret
            namespace: external-secrets
            key: access-key-id
          secretAccessKeySecretRef:
            name: awssm-secret
            namespace: external-secrets
            key: secret-access-key
```

👉 Apply it:

```bash
kubectl apply -f cluster-secret-store.yaml
```

---

## 🔄 Sync Secrets Automatically

### 1️⃣ Create a Secret in AWS Secrets Manager

```bash
aws secretsmanager create-secret \
  --name myapp/database-credentials \
  --secret-string '{"username":"root","password":"root"}'
```

---

### 2️⃣ Create an ExternalSecret Resource

🪸 Create a file named `db-external-secret.yaml`:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: argoapp
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-cluster-secret-store
    kind: ClusterSecretStore
  target:
    name: database-secret
  data:
    - secretKey: username
      remoteRef:
        key: myapp/database-credentials
        property: username
    - secretKey: password
      remoteRef:
        key: myapp/database-credentials
        property: password
```

👉 Apply it:

```bash
kubectl apply -f db-external-secret.yaml
```

---

## ✅ Verify the Synced Secret

```bash
kubectl get secrets -n argoapp
```

---

## 🛠 Using the Secrets in Your Application

In your **Deployment** manifest, reference the secret like this:

```yaml
env:
  - name: DB_USERNAME
    valueFrom:
      secretKeyRef:
        name: database-secret
        key: username
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: database-secret
        key: password
```

---


