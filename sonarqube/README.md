
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
echo "Access SonarQube at: http://$(kubectl get svc -n sonarqube sonarqube-sonarqube -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):9000"

# Default credentials:
# Username: admin
# Password: admin (change immediately)
```
