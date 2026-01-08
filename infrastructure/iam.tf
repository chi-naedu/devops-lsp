# 1. Create a Role for the EC2 Instance
# resource "aws_iam_role" "tools_role" {
#   name = "linksnap-tools-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = { Service = "ec2.amazonaws.com" }
#     }]
#   })
# }

# 2. Create the Policy (Allow reading ONLY our specific secret)
# resource "aws_iam_policy" "secrets_policy" {
#   name        = "linksnap-secrets-policy"
#   description = "Allow reading SonarQube DB credentials"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = [
#         "secretsmanager:GetSecretValue",
#         "secretsmanager:DescribeSecret"
#       ]
#       Effect   = "Allow"
#       Resource = aws_secretsmanager_secret.sonar_db_secret.arn
#     }]
#   })
# }

# 3. Attach Policy to Role
# resource "aws_iam_role_policy_attachment" "attach_secrets" {
#   role       = aws_iam_role.tools_role.name
#   policy_arn = aws_iam_policy.secrets_policy.arn
# }

# 4. Create Instance Profile (This is what we actually attach to the EC2)
# resource "aws_iam_instance_profile" "tools_profile" {
#   name = "linksnap-tools-profile"
#   role = aws_iam_role.tools_role.name
# }

# --- Jenkins IAM Role for ECR Access ---

# 1. The Trust Policy (Who can use this role? -> EC2)
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 2. The Permission Policy (What can they do? -> Read/Write to ECR)
resource "aws_iam_role_policy_attachment" "jenkins_ecr_policy" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# 3. The Instance Profile (The "Pass" to give to the server)
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_role.name
}