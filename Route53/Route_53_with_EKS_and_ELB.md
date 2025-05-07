
# 🛠️ **Setting up AWS Route 53 with EKS and ELB**

This guide walks you through configuring AWS Route 53 with your EKS cluster and connecting it to an external load balancer (ELB). Additionally, we cover how to provision an SSL certificate through AWS ACM (AWS Certificate Manager) for HTTPS support.

## 🔧 **Prerequisites**

- AWS Account with permissions to manage Route 53, IAM, and ACM.
- EKS Cluster up and running.
- AWS CLI installed and configured.
- kubectl installed and configured.

## 📌 **Step 1: Create AWS Route 53 Hosted Zone**

Create a hosted zone in Route 53 to manage your domain's DNS records.

```bash
export DOMAIN_NAME=itiproject.site

aws route53 create-hosted-zone --caller-reference $(uuidgen) --name $DOMAIN_NAME
```

### Add Name Servers to Your Domain

Once the hosted zone is created, Route 53 provides a set of name servers. Update your domain’s DNS settings with the following name servers:

```json
"DelegationSet": {
    "NameServers": [
        "ns-441.awsdns-55.com",
        "ns-1189.awsdns-20.org",
        "ns-655.awsdns-17.net",
        "ns-1730.awsdns-24.co.uk"
    ]
}
```

Update your domain registrar with these name servers to delegate the DNS resolution to Route 53.

---

## 📡 **Step 2: Set Up Load Balancer for EKS**

In EKS, expose your application via an external Load Balancer (ELB). To do so, modify your service YAML as follows:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-internal: "false"
spec:
  selector:
    app: myapp
  ports:
    - port: 80
      targetPort: 8080
  type: LoadBalancer
```

This configuration will create an external load balancer with a public DNS that can be used to point your domain to it.

---

## 🔒 **Step 3: Manually Provision SSL Certificate via AWS ACM**

To enable HTTPS for your domain, you need to provision an SSL certificate via **AWS ACM (AWS Certificate Manager)** and associate it with your load balancer.

### Request a Certificate in ACM

1. Navigate to **AWS ACM** in the AWS Console.
2. Request a **public certificate** for your domain `www.itiproject.site`.
3. Add domain validation (DNS validation is typically the easiest option).
4. After validation, the certificate will be issued.

---

## 🔗 **Step 4: Attach SSL Certificate to Load Balancer (ELB)**

Now, you can attach the issued SSL certificate to your ELB:

1. Navigate to **EC2 > Load Balancers** in the AWS Console.
2. Select your load balancer (created earlier for your service).
3. Under the **Listeners** tab, click **View/edit certificates**.
4. Add the SSL certificate you just created by selecting **Add Listener** for HTTPS on port 443.
5. Associate the certificate with the listener.

---

## 🌐 **Step 5: Update Route 53 to Point to Load Balancer**

Now, you need to update your Route 53 DNS settings to point to the newly created Load Balancer. First, retrieve the Load Balancer DNS name and Hosted Zone ID:

```bash
aws elbv2 describe-load-balancers
```

Example output:

```bash
k8s-argoapp-dbingres-2c826f4fcb-335049984.us-east-1.elb.amazonaws.com
Z35SXDOTRQ7X7K
```

Then create an **A record** in Route 53 to alias your domain to the Load Balancer's DNS name:

**alias-record.json**

```json
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
          "DNSName": "k8s-argoapp-dbingres-2c826f4fcb-335049984.us-east-1.elb.amazonaws.com",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
```

Apply the changes:

```bash
aws route53 change-resource-record-sets --hosted-zone-id Z35SXDOTRQ7X7K --change-batch file://alias-record.json
```

This creates a DNS alias record for `www.itiproject.site` that points to the ELB, allowing access to your application via HTTPS.

---

## 🛡️ **Step 6: Verify HTTPS Access**

To verify that HTTPS is working properly, open a browser and navigate to:

```
https://www.itiproject.site
```

You should now be able to access your application securely with a valid SSL certificate.

---


### 🔧 **Troubleshooting Tips**

- Ensure the DNS propagation is complete after updating the name servers in your domain registrar.
- If the SSL certificate fails to validate, double-check your DNS settings in Route 53.
- Ensure that your security groups allow inbound traffic on port 443 for HTTPS.
