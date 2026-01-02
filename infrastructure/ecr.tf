# --- Backend Repository (Python API) ---
resource "aws_ecr_repository" "backend" {
  name                 = "linksnap-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = { Name = "LinkSnap-Backend-Repo" }
}

# --- Frontend Repository (React/Nginx) ---
resource "aws_ecr_repository" "frontend" {
  name                 = "linksnap-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = { Name = "LinkSnap-Frontend-Repo" }
}

# --- Outputs (We need both URLs) ---
output "ecr_backend_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "ecr_frontend_url" {
  value = aws_ecr_repository.frontend.repository_url
}