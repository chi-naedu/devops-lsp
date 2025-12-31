#!/bin/bash
sudo apt-get update -y

# 1. Install Docker
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

# 2. Permissions
sudo usermod -aG docker ubuntu
sudo systemctl restart docker

# 3. Install AWS CLI & jq (Required for parsing secrets)
sudo apt-get install unzip jq -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install

# 4. Retrieve Credentials from Secrets Manager
# We use the region and secret_id passed from Terraform
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id ${secret_id} --region ${region} --query SecretString --output text)

# Parse the JSON using jq
DB_USER=$(echo $SECRET_JSON | jq -r .username)
DB_PASS=$(echo $SECRET_JSON | jq -r .password)

echo "Retrieved DB Credentials for user: $DB_USER"

# ... (SonarQube Kernel Fix) ...
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf

# 5. Create Docker Compose with INJECTED Credentials
mkdir -p /home/ubuntu/tools
cat <<EOF > /home/ubuntu/tools/docker-compose.yml
version: '3.8'
services:
  sonarqube:
    image: sonarqube:lts-community
    container_name: sonarqube
    ports:
      - "9000:9000"
    environment:
      - SONAR_JDBC_URL=jdbc:postgresql://${db_endpoint}/sonarqube
      - SONAR_JDBC_USERNAME=$DB_USER
      - SONAR_JDBC_PASSWORD="$DB_PASS"
      - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
    volumes:
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs

  nexus:
    image: sonatype/nexus3
    container_name: nexus
    ports:
      - "8081:8081"
    volumes:
      - nexus_data:/nexus-data

volumes:
  sonarqube_extensions:
  sonarqube_logs:
  nexus_data:
EOF

# Start Tools
cd /home/ubuntu/tools
sudo docker compose up -d