# 1. The File System
resource "aws_efs_file_system" "jenkins_efs" {
  creation_token = "jenkins-efs"
  encrypted      = true
  tags = { Name = "Jenkins-EFS" }
}

# 2. Mount Target for Subnet 1 (Zone A)
resource "aws_efs_mount_target" "mount_a" {
  file_system_id  = aws_efs_file_system.jenkins_efs.id
  subnet_id       = aws_subnet.public_subnet_1.id
  security_groups = [aws_security_group.efs_sg.id]
}

# 3. Mount Target for Subnet 2 (Zone B)
resource "aws_efs_mount_target" "mount_b" {
  file_system_id  = aws_efs_file_system.jenkins_efs.id
  subnet_id       = aws_subnet.public_subnet_2.id
  security_groups = [aws_security_group.efs_sg.id]
}