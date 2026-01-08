# # 1. Generate a random password
# resource "random_password" "db_password" {
#   length           = 16
#   special          = true
#   override_special = "_%-"  # To avoid issues with certain special characters
# }

# # 2. Create the Secret Container
# resource "aws_secretsmanager_secret" "sonar_db_secret" {
#   name = "linksnap/sonarqube/db_credentials"
#   tags = { Name = "SonarQube DB Secret" }
# }

# # 3. Store the Password in the Secret
# resource "aws_secretsmanager_secret_version" "sonar_db_secret_val" {
#   secret_id     = aws_secretsmanager_secret.sonar_db_secret.id
#   secret_string = jsonencode({
#     username = "sonar"
#     password = random_password.db_password.result
#   })
# }