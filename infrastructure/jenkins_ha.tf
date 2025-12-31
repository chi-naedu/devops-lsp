# 1. The Blueprint (Launch Template)
resource "aws_launch_template" "jenkins_lt" {
  name_prefix   = "jenkins-lt-"
  image_id      = var.ami_id
  instance_type = "t3.large"
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  # Inject the script, passing the EFS ID and Region as variables
  user_data = base64encode(templatefile("${path.module}/scripts/install_jenkins.sh", {
    efs_id     = aws_efs_file_system.jenkins_efs.id,
    aws_region = var.aws_region
  }))

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "Jenkins-HA-Instance" }
  }
}

# 2. The Manager (Auto Scaling Group)
resource "aws_autoscaling_group" "jenkins_asg" {
  name                = "jenkins-asg"
  vpc_zone_identifier = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  
  # Min 1, Max 2 = Self Healing (Always keep at least 1 running, but allow scaling up)
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.jenkins_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Jenkins-ASG-Node"
    propagate_at_launch = true
  }
}