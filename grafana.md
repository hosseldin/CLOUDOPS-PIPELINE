
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.service.type=ClusterIP \
  --set grafana.adminPassword=admin




jenkins


kubectl delete validatingwebhookconfiguration ingress-nginx-admission
