# 1. Subnet Group (Where can the DB live?)
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "linksnap-rds-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  
  tags = { Name = "LinkSnap RDS Subnet Group" }
}

# 2. The Database Instance
resource "aws_db_instance" "sonar_db" {
  allocated_storage    = 20
  db_name              = "sonarqube"
  engine               = "postgres"
  engine_version       = "14" # SonarQube supports Postgres 11-15
  instance_class       = "db.t3.micro" # Free tier eligible
  username             = "sonar"
  password             = random_password.db_password.result
  parameter_group_name = "default.postgres14"
  skip_final_snapshot  = true
  publicly_accessible  = false
  
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = { Name = "SonarQube-DB" }
}