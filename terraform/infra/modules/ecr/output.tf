output "repo_name" {
  value = aws_ecr_repository.app_repo.name
  
}
output "repo_url" {
  value = aws_ecr_repository.app_repo.repository_url
}