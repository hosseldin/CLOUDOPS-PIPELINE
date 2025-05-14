resource "aws_ecr_repository" "app_repo" {
  name = var.repo_name

  image_scanning_configuration {
    scan_on_push = true
  }
}
