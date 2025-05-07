# ⚙️ Infrastructure Provisioning with Terraform 🚀

This repository uses **Terraform** to provision a robust AWS infrastructure foundation, including networking, routing, a production-grade EKS cluster, and IAM roles & policies for key platform components. Each major component is organized into reusable Terraform modules for clarity and scalability.

---

## 🔧 Terraform Modules Provision

* **🌐 Networking**: VPC with 3 public and 3 private subnets across 3 Availability Zones
* **🚪 Gateways & Routing**: Internet Gateway, NAT Gateways, and Route Tables
* **🐝 EKS Cluster**: Managed control plane and auto-scaled node groups in private subnets
* **🔒 IAM**: Roles & policies for core services (EKS, Jenkins, ArgoCD, External Secrets Operator)

---

1. Initialize the workspace:
   ```bash
   terraform init

2. Apply the configuration:

   ```bash
   terraform apply -auto-approve
   
---

## 📦 Directory Structure 📂

```bash
terraform/ 🔧
├── modules/ 🧩                # Reusable modules
│   ├── vpc/ 🌐                # Networking: VPC, Subnets, Gateways, Routes
│   ├── eks/ 🐝                # Kubernetes: EKS control plane & Node Groups
│   └── iam/ 🔒                # Security: IAM Roles & Policies
├── .terraform.lock.hcl 📌       # Lockfile for provider version consistency
├── bastion.tf 🏰               # Bastion host configuration
├── data.tf 📊                  # Data sources (AZs, AMIs, etc.)
├── ecr.tf 📦                   # ECR repository provisioning
├── main.tf 🚀                  # Root module orchestration
├── providers.tf 🔗            # Provider configurations (AWS, Helm, etc.)
├── terraform.tfstate 🗄️         # Terraform state (local file)
└── terraform.tfstate.backup 💾 # Backup of previous state
```

![image](https://github.com/user-attachments/assets/02f5c99e-72d3-42f7-860b-fa4f1d0116c7)

