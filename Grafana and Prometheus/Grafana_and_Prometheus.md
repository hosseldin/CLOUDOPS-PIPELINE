
# **Prometheus and Grafana Setup with Helm** 📊🚀

This section outlines the steps to install **Prometheus** and **Grafana** using Helm, as part of the **Kube-Prometheus-Stack** for Kubernetes monitoring.

### 1️⃣ **Add the Prometheus Community Helm Repository** 📦

Before installing Prometheus and Grafana, we need to add the Helm repository containing the necessary charts.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

- **Explanation:**
  - `helm repo add` adds the **Prometheus Community** Helm chart repository to your local Helm configuration.
  - `helm repo update` fetches the latest charts and updates your local Helm repository.

### 2️⃣ **Install the Kube-Prometheus-Stack** 🔧

Once the repository is updated, you can install the **Kube-Prometheus-Stack** chart, which includes Prometheus, Grafana, and various Kubernetes monitoring components.

```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.service.type=ClusterIP \
  --set grafana.adminPassword=admin
```

- **Explanation:**
  - `helm install prometheus` is the command to install the **Kube-Prometheus-Stack** chart, naming the release `prometheus`.
  - `--namespace monitoring` specifies the namespace where Prometheus and Grafana will be deployed.
  - `--create-namespace` creates the `monitoring` namespace if it doesn't already exist.
  - `--set prometheus.service.type=ClusterIP` configures Prometheus to expose its service internally within the Kubernetes cluster (default behavior for internal communication).
  - `--set grafana.adminPassword=admin` sets the initial admin password for Grafana. You should replace `admin` with a more secure password for production environments.

### 3️⃣ **Verify Installation** ✅

After running the above Helm command, you can check if the resources are properly installed:

```bash
kubectl get pods -n monitoring
```

This command will show the pods running in the `monitoring` namespace, including Prometheus, Grafana, and other related components.
![image](https://github.com/user-attachments/assets/c1636689-8f54-4cff-b36a-3c71d52b73b6)

