
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

# Access in browser (port 9000) or if you have a url
echo "Access SonarQube at: http://$(kubectl get svc -n sonarqube sonarqube-sonarqube -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):9000"

# Default credentials:
# Username: admin
# Password: admin 
```


## ✅ Step 6: Create a New Project in SonarQube

1. Click **“Projects”** from the top menu.
2. Click **“Create Project”**.
3. Choose **“Manually”** (not from GitHub/GitLab).
4. Fill in:

   * **Project key**: e.g., `node-app-jenkins`
   * **Display name**: something readable, like `Node.js Jenkins App`
5. Click **“Set Up”**.

---

## ✅ Step 7: Generate a Token

After setting up the project manually, SonarQube will ask how you want to analyze the code.

1. Choose **“Other”** (not Maven, Gradle, etc.)
2. Click **“Generate a token”**

   * Give it a name like `jenkins-token`
3. Click **“Generate”** and **copy the token** — you will **not** see it again.
4. Choose **“SonarScanner CLI”** as the method.

---

## ✅ Step 8: Save Token in Jenkins

1. Go to **Jenkins → Manage Jenkins → Manage Credentials**
2. Select the domain or add a new one.
3. Click **“Add Credentials”**

   * **Kind**: `Secret text`
   * **Secret**: paste the **SonarQube token**
   * **ID**: e.g., `sonarqube-token`
   * **Description**: `SonarQube Token`

---

## ✅ Step 9: Configure SonarQube Server in Jenkins

1. Go to **Jenkins → Manage Jenkins → Configure System**
2. Scroll to **“SonarQube servers”**
3. Click **“Add SonarQube”**

   * **Name**: `MySonarQubeServer`
   * **Server URL**: `http://<your-sonarqube-url>:9000`
   * **Server authentication token**:

     * Select the credentials you added (`sonarqube-token`)
4. Check the box **“Enable injection of SonarQube server configuration as build environment variables”**

Click **Save**.

---

## ✅ Step 10: Use the Info in Jenkins Pipeline

Now you can use this token and server in your pipeline stage using:

```groovy
withSonarQubeEnv('MySonarQubeServer') {
    sh """
        sonar-scanner \
        -Dsonar.projectKey=node-app-jenkins \
        -Dsonar.sources=${TARGET_FOLDER} \
        -Dsonar.host.url=$SONAR_HOST_URL \
        -Dsonar.login=$SONAR_AUTH_TOKEN
    """
}
```

> Jenkins will automatically inject `$SONAR_HOST_URL` and `$SONAR_AUTH_TOKEN` using the values from the SonarQube configuration.

---

## ✅ Done!

SonarQube will now analyze your code when the Jenkins job runs.
After each run, visit **SonarQube → Projects → Your Project** to view:

* Code quality issues
* Vulnerabilities
* Code smells
* Coverage (if configured)

---
