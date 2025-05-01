
export AWS_DEFAULT_OUTPUT=json # ❗ Use JSON output for this tutorial
export AWS_DEFAULT_REGION=us-east-1   # ❗ Your AWS region.

export DOMAIN_NAME=itiproject.net


aws route53 create-hosted-zone --caller-reference $(uuidgen) --name $DOMAIN_NAME



add this

    "DelegationSet": {
        "NameServers": [
            "ns-441.awsdns-55.com",
            "ns-1189.awsdns-20.org",
            "ns-655.awsdns-17.net",
            "ns-1730.awsdns-24.co.uk"
        ]
    }


to your domain

export CLUSTER=eks-cluster

helm install cert-manager cert-manager \
  --repo https://charts.jetstack.io \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true


kubectl explain Certificate
kubectl explain CertificateRequest
kubectl explain Issuer

# connect aws route53 with your elb
# alias-record.json
{
  "Comment": "Creating an alias record",
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "www.\($DOMAIN_NAME)",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": .CanonicalHostedZoneNameID,
          "DNSName": .CanonicalHostedZoneName,
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}'

# from this commad you can get load balancer dns and HostedZoneId of it
aws elbv2 describe-load-balancers

# for example
k8s-argoapp-dbingres-2c826f4fcb-335049984.us-east-1.elb.amazonaws.com
Z35SXDOTRQ7X7K

# for example 
{
  "Comment": "Creating an alias record",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "www.itiproject.site",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z35SXDOTRQ7X7K",
          "DNSName": "k8s-argoapp-dbingres-2c826f4fcb-1833408552.us-east-1.elb.amazonaws.com",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}



# get hosted_zone_id of aws route53 zone
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "itiproject.site" --query "HostedZones[0].Id" --output text)

# this command will create a new record that point to ingress of out application
aws route53 change-resource-record-sets --hosted-zone-id Z0456625ON2PZX3C127J --change-batch file://alias-record.json


# clusterissuer-selfsigned.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned
spec:
  selfSigned: {}

kubectl apply -f clusterissuer-selfsigned.yaml


# certificate.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: www
  namespace: argoapp
spec:
  secretName: www-tls
  revisionHistoryLimit: 1
  privateKey:
    rotationPolicy: Always
  commonName: www.$DOMAIN_NAME
  dnsNames:
    - www.$DOMAIN_NAME
  usages:
    - digital signature
    - key encipherment
    - server auth
  issuerRef:
    name: selfsigned
    kind: ClusterIssuer


envsubst < certificate.yaml | kubectl apply -f -

# install cmctl  "go should be installed"
OS=$(go env GOOS); ARCH=$(go env GOARCH); curl -fsSL -o cmctl https://github.com/cert-manager/cmctl/releases/latest/download/cmctl_${OS}_${ARCH}
chmod +x cmctl
sudo mv cmctl /usr/local/bin



# to make load balancer public add this to yaml
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-internal: "false"



eksctl utils associate-iam-oidc-provider --cluster $CLUSTER --approve

aws iam create-policy \
     --policy-name cert-manager-acme-dns01-route53 \
     --description "This policy allows cert-manager to manage ACME DNS01 records in Route53 hosted zones. See https://cert-manager.io/docs/configuration/acme/dns01/route53" \
     --policy-document file:///dev/stdin <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:GetChange",
      "Resource": "arn:aws:route53:::change/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/*"
    },
    {
      "Effect": "Allow",
      "Action": "route53:ListHostedZonesByName",
      "Resource": "*"
    }
  ]
}
EOF


AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
eksctl create iamserviceaccount \
  --name cert-manager-acme-dns01-route53 \
  --namespace cert-manager \
  --cluster ${CLUSTER} \
  --role-name cert-manager-acme-dns01-route53 \
  --attach-policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/cert-manager-acme-dns01-route53 \
  --approve


# rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cert-manager-acme-dns01-route53-tokenrequest
  namespace: cert-manager
rules:
  - apiGroups: ['']
    resources: ['serviceaccounts/token']
    resourceNames: ['cert-manager-acme-dns01-route53']
    verbs: ['create']
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cert-manager-acme-dns01-route53-tokenrequest
  namespace: cert-manager
subjects:
  - kind: ServiceAccount
    name: cert-manager
    namespace: cert-manager
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: cert-manager-acme-dns01-route53-tokenrequest


kubectl apply -f rbac.yaml


# clusterissuer-lets-encrypt-staging.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: menasafwat952@gmail.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - dns01:
        route53:
          region: us-east-1
          role: arn:aws:iam::${AWS_ACCOUNT_ID}:role/cert-manager-acme-dns01-route53
          auth:
            kubernetes:
              serviceAccountRef:
                name: cert-manager-acme-dns01-route53


kubectl apply -f clusterissuer-lets-encrypt-staging.yaml 

kubectl describe clusterissuer letsencrypt-staging

# to make sure that certificate is issued
cmctl status certificate www
cmctl inspect secret www-tls




argocd subdomain

https://medium.com/@tanmoysantra67/setting-up-argocd-with-https-on-kubernetes-using-aws-alb-d29e58b80d72