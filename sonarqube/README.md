Here's a concise `README.md` file covering everything up to accessing SonarQube, with all configurations in one file:

```markdown
# SonarQube on EKS Deployment Guide

## Prerequisites
- Running Amazon EKS cluster
- `kubectl` and `helm` configured
- AWS CLI with proper permissions

## 1. Node Preparation
```bash
# List available nodes
kubectl get nodes

# Label your dedicated node
kubectl label nodes <node-name> sonarqube=true

# Verify label
kubectl describe node <node-name> | grep Labels

# Add taint to prevent other workloads
kubectl taint nodes <node-name> sonarqube=true:NoSchedule
```

## 2. Monitoring Secret Setup
```bash
kubectl create secret generic sonarqube-monitoring-secret \
  -n sonarqube \
  --from-literal=passcode=your-strong-password-here
```

## 3. Helm Configuration (sonar-values.yaml)
```yaml
# sonar-values.yaml
nodeSelector:
  sonarqube: "true"

tolerations:
- key: "sonarqube"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"

monitoring:
  passcodeSecretName: "sonarqube-monitoring-secret"
  passcodeSecretKey: "passcode"

persistence:
  enabled: true
  storageClass: "gp2"
  size: 10Gi
  accessMode: ReadWriteOnce

postgresql:
  enabled: true
  persistence:
    enabled: true
    size: 10Gi

service:
  type: LoadBalancer
  ports:
    web: 9000

resources:
  requests:
    memory: "2Gi"
    cpu: "1000m"
  limits:
    memory: "4Gi"
    cpu: "2000m"
```

## 4. Installation
```bash
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm repo update

helm upgrade --install sonarqube sonarqube/sonarqube \
  --version 8.0.0 \
  -n sonarqube \
  -f sonar-values.yaml \
  --wait
```

## 5. Accessing SonarQube
```bash
# Get the LoadBalancer URL
kubectl get svc -n sonarqube sonarqube-sonarqube -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Access in browser (port 9000)
echo "Access SonarQube at: http://$(kubectl get svc sonarqube-sonarqube -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):9000"

# Default credentials:
# Username: admin
# Password: admin (change immediately)
```

Save this as `README.md` in your project directory. This single file contains all the instructions from setup to accessing the instance, with:
- Clear section headers
- Copy-paste ready commands
- Complete Helm values configuration
- Access instructions with auto-generated URL output
- All critical information in one place