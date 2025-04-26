resource "aws_ecr_repository" "app_repo" {
  name                 = "node-app-jenkins"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# IAM role for ECR access
resource "aws_iam_role" "ecr_access_role" {
  name = "ecr-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "ecr_access_profile" {
  name = "ecr-access-instance-profile"
  role = aws_iam_role.ecr_access_role.name
}

# IAM policy for ECR access
resource "aws_iam_role_policy" "ecr_pull_policy" {
  name = "ecr-pull-policy"
  role = aws_iam_role.ecr_access_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:CompleteLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage"

        ],
        Resource = "*"
      },
    ]
  })
}


output "ecr_profile" {
  value = aws_iam_instance_profile.ecr_access_profile.name
}


output "aws_ecr_repository" {
  value = aws_ecr_repository.app_repo.repository_url
  
}