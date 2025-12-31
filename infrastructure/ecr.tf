resource "aws_ecr_repository" "app_repo" {
  name                 = "linksnap-app"
  image_tag_mutability = "MUTABLE" # Allows overwriting tags like 'latest'

  image_scanning_configuration {
    scan_on_push = true # Free security scan for vulnerabilities
  }

  tags = { Name = "LinkSnap-ECR" }
}

# Output the URL so we can use it in Jenkins later
output "ecr_repository_url" {
  value = aws_ecr_repository.app_repo.repository_url
}