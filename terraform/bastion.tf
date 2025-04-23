# IAM Role
resource "aws_iam_role" "bastion_role" {
  name = "bastion-eks-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach necessary policies for EKS access
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_read_only" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


resource "aws_iam_instance_profile" "bastion_instance_profile" {
  name = "bastion-instance-profile"
  role = aws_iam_role.bastion_role.name
}



# Security Group
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_key_pair" "my_key" {
  key_name   = "my-aws-key"
  public_key = file("${path.module}/my-aws-key.pub")
}

# Bastion EC2 Instance
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  associate_public_ip_address = true
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = aws_key_pair.my_key.key_name

  iam_instance_profile   = aws_iam_instance_profile.bastion_instance_profile.name

  tags = {
    Name = "eks-bastion"
  }

user_data = <<-EOF
        #!/bin/bash
        set -ex

        # Update system
        yum update -y

        # Install dependencies
        yum install -y unzip curl tar gzip

        # Install AWS CLI v2
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        ./aws/install
        rm -rf awscliv2.zip aws

        # Install kubectl
        curl -LO "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl"
        curl -LO "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl.sha256"
        echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
        chmod +x kubectl
        mv kubectl /usr/local/bin/
        rm kubectl.sha256
        echo "kubectl v1.29.0 installed"

        # Install Helm
        curl -LO "https://get.helm.sh/helm-v3.14.0-linux-amd64.tar.gz"
        tar -zxvf "helm-v3.14.0-linux-amd64.tar.gz"
        mv linux-amd64/helm /usr/local/bin/helm
        rm -rf linux-amd64 "helm-v3.14.0-linux-amd64.tar.gz"
        echo "helm v3.14.0 installed"

        # Install eksctl
        curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
        mv /tmp/eksctl /usr/local/bin
        echo "eksctl installed"

        # Configure bash environment
        cat <<EOT >> ~/.bashrc
        # Kubernetes and Helm completions
        source <(kubectl completion bash)
        source <(helm completion bash)
        alias k=kubectl
        complete -F __start_kubectl k
        export PATH=$PATH:/usr/local/bin
        EOT

        # Install jq for JSON processing
        yum install -y jq

        # Verify installations
        echo "=== Versions ==="
        aws --version
        kubectl version --client --short
        helm version --short
        eksctl version
        
        aws eks update-kubeconfig --name eks-cluster --region us-west-2
        EOF

}

# Output the Bastion Host Public IP
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

resource "aws_eks_access_entry" "admin_access" {
  cluster_name  = module.eks.cluster_name
  principal_arn =  aws_iam_role.bastion_role.arn   # Replace with your IAM user/role
  type          = "STANDARD"  # or "EC2_LINUX" for nodes
}


# Attach AmazonEKSAdminPolicy to the access entry
resource "aws_eks_access_policy_association" "root_policy" {
  cluster_name  = module.eks.cluster_name
  principal_arn  = aws_eks_access_entry.admin_access.principal_arn
  policy_arn     = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }

}