#!/bin/bash
# Note: Terraform will replace ${efs_id} with the actual ID

# 1. Update and Install Dependencies
sudo apt-get update -y
sudo apt-get install -y nfs-common openjdk-17-jre

# 2. Setup Jenkins Home Directory on EFS
# Create the mount point
sudo mkdir -p /var/lib/jenkins

# Mount EFS (Using the Terraform variable)
# We use the region-agnostic DNS format for EFS
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_id}.efs.${aws_region}.amazonaws.com:/ /var/lib/jenkins

# Make mount permanent in /etc/fstab (so it survives reboot)
echo "${efs_id}.efs.${aws_region}.amazonaws.com:/ /var/lib/jenkins nfs4 defaults,_netdev 0 0" | sudo tee -a /etc/fstab

# 3. Install Jenkins (Now it will install INTO the EFS mount)
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update -y
sudo apt-get install jenkins -y

# 4. Install Docker & Permissions
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu
sudo systemctl restart docker

# 5. Fix ownership (Since EFS might be owned by root initially)
sudo chown -R jenkins:jenkins /var/lib/jenkins
sudo systemctl restart jenkins

# 6. Install Tools (AWS CLI, Trivy)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get install unzip -y
unzip awscliv2.zip
sudo ./aws/install

sudo apt-get install -y python3-venv libatomic1

sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy -y

echo "Jenkins HA Setup Complete!"