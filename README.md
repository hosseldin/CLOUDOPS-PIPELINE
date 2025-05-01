# CLOUDOPS-PIPELINE
Official Repo for the Full GitOps Pipeline on AWS with Terraform, and Secrets Management Project


# command to connect your kubectl to eks cluster
aws eks update-kubeconfig --name eks-cluster --region us-east-1

# include in terraform code
curl https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.12.0/docs/install/iam_policy.json -o iam_policy.json

# control it to create it wihtout account id
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json


eksctl utils associate-iam-oidc-provider --region=us-east-1 --cluster=eks-cluster --approve

eksctl create iamserviceaccount \
    --cluster=eks-cluster \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=arn:aws:iam::773893527461:policy/AWSLoadBalancerControllerIAMPolicy \
    --override-existing-serviceaccounts \
    --region us-east-1 \
    --approve

if error happend delete it using this command

eksctl delete iamserviceaccount \
  --name aws-load-balancer-controller \
  --namespace kube-system \
  --cluster eks-cluster \
  --region us-west-2



helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

kubectl get deployment -n kube-system aws-load-balancer-controller


https://www.jenkins.io/doc/book/installing/kubernetes/


# ebs driver


eksctl create iamserviceaccount \
        --name ebs-csi-controller-sa \
        --namespace kube-system \
        --cluster eks-cluster \
        --role-name AmazonEKS_EBS_CSI_DriverRole \
        --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
        --region us-east-1 \
        --approve \
        --override-existing-serviceaccounts
        --role only


eksctl delete iamserviceaccount \
  --name aws-load-balancer-controller \
  --namespace kube-system \
  --cluster eks-cluster \
  --region us-west-2


#
create service account to loadbalancer
create service account to ebs
create service account to jenkins
create service account to argocd

  
1- install jenkins using helm chart 
 helm repo add jenkinsci https://charts.jenkins.io
 helm repo update
 -- create namespace
 kubectl create namespce jenkins-ns
 -- edit values.yml to and    serviceType: LoadBalancer  and then install helm chart
  helm show values jenkinsci/jenkins > /tmp/jenkins.yml 
 i edited in this file to pass it while downloading  

    ingress:
      enabled: true
      annotations:
        kubernetes.io/ingress.class: alb
        alb.ingress.kubernetes.io/scheme: internet-facing
        alb.ingress.kubernetes.io/target-type: ip
        alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
      path: /*
      hosts:
        - jenkins.example.com


# we can use jenkins.yml for this 


 -- install chart
helm install jenkins jenkinsci/jenkins --values /tmp/jenkins.yml -n jenkins-ns
# get jenkins password
kubectl exec --namespace jenkins-ns -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
# get ip of loadbalancer
  export SERVICE_IP=$(kubectl get svc --namespace jenkins-ns jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  echo http://$SERVICE_IP:8080

 


1. Create IAM User and Policy
- Create IAM Policy:
aws iam create-policy \
    --policy-name jenkins-ecr-policy \
    --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:DescribeRepositories",
                "ecr:ListImages",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload"
            ],
            "Resource": "*"
        }
    ]
}'

- Create IAM User:
aws iam create-user --user-name jenkins-ecr
aws iam attach-user-policy --user-name jenkins-ecr --policy-arn arn:aws:iam::214797541313:policy/jenkins-ecr-policy
aws iam create-access-key --user-name jenkins-ecr

2- Create ECR Repository
aws ecr create-repository \
    --repository-name kanikotest \
    --region us-west-2
    
    
3- kubectl create secret generic aws-credentials \
    --from-literal="AWS_ACCESS_KEY_ID=*********" \
    --from-literal="AWS_SECRET_ACCESS_KEY=********" \
    -n jenkins-ns
    
----pipeline
pipeline {
  agent {
    kubernetes {
      yaml '''
        apiVersion: v1
        kind: Pod
        metadata:
          name: kaniko
          namespace: jenkins-ns
        spec:
          containers:
          - name: kaniko
            image: gcr.io/kaniko-project/executor:debug
            command:
            - /busybox/cat
            tty: true
            env:
            - name: AWS_ACCESS_KEY_ID
              valueFrom:
                secretKeyRef:
                  name: aws-credentials
                  key: AWS_ACCESS_KEY_ID
            - name: AWS_SECRET_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: aws-credentials
                  key: AWS_SECRET_ACCESS_KEY
            volumeMounts:
              - name: aws-config
                mountPath: /kaniko/.aws
          volumes:
            - name: aws-config
              secret:
                secretName: aws-credentials
      '''
    }
  }

  environment {
    AWS_REGION = 'us-east-1'
    ECR_REGISTRY = '214797541313.dkr.ecr.us-east-1.amazonaws.com'
    ECR_REPOSITORY = 'kanikotest'
  }

  stages {
    stage('Build & Push to ECR') {
      steps {
        container('kaniko') {
          script {
            // Configure Docker credentials for ECR
            sh """
              # Create the Docker config directory
              mkdir -p /kaniko/.docker

              # Create config.json with ECR credentials helper
              echo '{
                "credHelpers": {
                  "${ECR_REGISTRY}": "ecr-login"
                }
              }' > /kaniko/.docker/config.json

              # Build and push using Kaniko
              /kaniko/executor \
                --context=git://github.com/hosseldin/CLOUDOPS-APP-PIPELINE.git#refs/heads/main \
                --context-sub-path=nodeapp \
                --dockerfile=Dockerfile \
                --destination=${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}
            """
          }
        }
      }
    }
  }
}



https://argocd-image-updater.readthedocs.io/en/latest/basics/update-methods/

https://medium.com/@CloudifyOps/automating-continuous-delivery-with-argocd-image-updater-bcd4a84ff858
------------
installing argocd --
------------
kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd --namespace argocd
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc -n argocd argocd-server
 You will see an EXTERNAL-IP field populated (takes a few minutes).

by default credentials
admin
password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d


kubectl create namespace argoapp

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argotest-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/M-Samii/Argo-repo.git
    targetRevision: HEAD
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: argoapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true

 --- argocd image updator---
 -- install argocd image updator




kubectl create namespace argoimage

# to delete all
kubectl delete clusterrole argocd-image-updater
kubectl delete clusterrolebinding argocd-image-updater
kubectl delete deployment argocd-image-updater -n argocd
kubectl delete serviceaccount argocd-image-updater -n argocd



--create secret for ecr this will handle kubernates get images from ecr
kubectl create secret docker-registry ecr-creds \
  --docker-server=773893527461.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  --docker-email=menasafwat952@gmail.com \



aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 214797541313.dkr.ecr.us-east-1.amazonaws.com

# create a gitops repo in github
# generate ssh key
ssh-keygen
# put the public key in deploy keys application



vi image-updater-values.yaml
config:
 registries:
   - name: ECR
     api_url: https://773893527461.dkr.ecr.us-east-1.amazonaws.com
     prefix: "773893527461.dkr.ecr.us-east-1.amazonaws.com"
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
     aws ecr --region "us-east-1" get-authorization-token --output text --query 'authorizationData[].authorizationToken' | base64 -d


# uninstall 
helm uninstall argocd-image-updater -n argocd

 helm upgrade --install argocd-image-updater argo/argocd-image-updater   --namespace argocd   -f image-updater-values.yaml

# to check logs
kubectl logs -n argocd deploy/argocd-image-updater


kubectl -n argocd  create secret generic git-creds   --from-file=sshPrivateKey=/home/ec2-user/.ssh/id_rsa

# this 
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
   path: k8s
   repoURL: https://github.com/mina-safwat-1/test_argo.git
   targetRevision: HEAD
 sources: []
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


