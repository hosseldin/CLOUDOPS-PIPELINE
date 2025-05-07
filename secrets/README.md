
# External Secrets Operator with AWS Secrets Manager

This guide explains how to set up the [External Secrets Operator](https://external-secrets.io) with **AWS Secrets Manager** to automatically sync secrets into your Kubernetes cluster.

---

## 🛠️ **Installation**

### 1️⃣ **Add the Helm Repository:**

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
```

### 2️⃣ **Install the External Secrets Operator:**

```bash
helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets \
  --create-namespace \
  --set installCRDs=true
```

### 3️⃣ **Verify Installation:**

```bash
kubectl get pods -n external-secrets
```

---

## 🔐 **Connect to AWS Secrets Manager**

### 1️⃣ **Create an IAM Policy for Secrets Access**

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

### 2️⃣ **Create a Kubernetes Secret with AWS Credentials**

Now, create a Kubernetes secret containing your AWS access credentials:

```bash
kubectl create secret generic awssm-secret \
  -n external-secrets \
  --from-literal=access-key-id=<YOUR_ACCESS_KEY_ID> \
  --from-literal=secret-access-key=<YOUR_SECRET_ACCESS_KEY>
```

---

### 3️⃣ **Create a ClusterSecretStore**

🪸 Create a file named `cluster-secret-store.yaml` with the following content:

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

👉 Apply it to the cluster:

```bash
kubectl apply -f cluster-secret-store.yaml
```

---

## 🔄 **Sync Secrets Automatically**

### 1️⃣ **Create a Secret in AWS Secrets Manager**

Create a secret in AWS Secrets Manager to store your application credentials:

```bash
aws secretsmanager create-secret \
  --name myapp/database-credentials \
  --secret-string '{"username":"root","password":"root"}'
```

---

### 2️⃣ **Create an ExternalSecret Resource**

🪸 Create a file named `db-external-secret.yaml` with the following content:

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

👉 Apply the ExternalSecret resource to your cluster:

```bash
kubectl apply -f db-external-secret.yaml
```

---

## ✅ **Verify the Synced Secret**

You can verify that the secret has been synced successfully by checking the secret in your Kubernetes cluster:

```bash
kubectl get secrets -n argoapp
```

---

## 🛠 **Using the Secrets in Your Application**

Now, in your *Deployment* manifest, reference the synced secret:

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

This setup will allow the **External Secrets Operator** to automatically sync secrets from **AWS Secrets Manager** into your Kubernetes cluster and make them available to your applications securely.
