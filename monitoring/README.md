
# **Prometheus and Grafana Setup with Helm** 📊🚀

This section outlines the steps to install **Prometheus** and **Grafana** using Helm as part of the **Kube-Prometheus-Stack**, and how to expose **Grafana** externally via an **ALB Ingress**.

---

### 1️⃣ **Add the Prometheus Community Helm Repository** 📦

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

> ✅ This adds and updates the Prometheus Community Helm chart repository.

---

### 2️⃣ **Install the Kube-Prometheus-Stack** 🔧

```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.service.type=ClusterIP \
  --set grafana.adminPassword=admin \
  --set grafana.service.port=80 \
  --set grafana.service.targetPort=3000 \
  --set grafana.service.type=NodePort
```

> ⚠️ For production, change the `grafana.adminPassword` to a secure value.

---

### 3️⃣ **Expose Grafana Using ALB Ingress** 🌐

Create a file named `grafana-ingress.yaml` with the following content:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: monitoring
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/healthcheck-port: "80"
    alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=60
    alb.ingress.kubernetes.io/group.name: itiproject-alb
    alb.ingress.kubernetes.io/backend-protocol: HTTP
    alb.ingress.kubernetes.io/ssl-redirect: '443'
spec:
  ingressClassName: alb
  tls:
    - hosts:
        - grafana.itiproject.site
  rules:
    - host: grafana.itiproject.site
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-grafana
                port:
                  number: 80
```

Then apply it:

```bash
kubectl apply -f grafana-ingress.yaml
```

> 🔒 Make sure your DNS (e.g. Route53) points `grafana.itiproject.site` to the ALB created by the Load Balancer Controller.

---

### 4️⃣ **Verify Installation** ✅

```bash
kubectl get pods -n monitoring
```

This command shows all pods related to Prometheus, Grafana, and exporters running under the `monitoring` namespace.

> 🌐 After successful setup, you should be able to access Grafana via:
> [https://grafana.itiproject.site](https://grafana.itiproject.site)
> *(Use the admin password set earlier to log in.)*


![image](https://github.com/user-attachments/assets/c1636689-8f54-4cff-b36a-3c71d52b73b6)
