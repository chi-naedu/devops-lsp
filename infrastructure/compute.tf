# Tools Server (SonarQube + Nexus)
# resource "aws_instance" "tools_server" {
#   ami           = var.ami_id
#   instance_type = "t3.medium"
#   subnet_id     = aws_subnet.public_subnet_2.id
#   key_name      = var.key_name
#   vpc_security_group_ids = [aws_security_group.tools_sg.id]
#   iam_instance_profile = aws_iam_instance_profile.tools_profile.name

#   # Inject Database Credentials into the script
#   user_data = base64encode(templatefile("${path.module}/scripts/install_tools.sh", {
#     db_endpoint = aws_db_instance.sonar_db.endpoint
#     secret_id   = aws_secretsmanager_secret.sonar_db_secret.name, # Pass the Name/ID
#     region      = var.aws_region
#   }))

#   root_block_device {
#     volume_size = 20
#   }

#   tags = { Name = "Tools-Server" }
# }