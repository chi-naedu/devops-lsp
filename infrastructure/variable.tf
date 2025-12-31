variable "aws_region" {
  description = "AWS Region to deploy resources"
  default     = "eu-west-2"  # Change this if you prefer us-west-2, eu-west-2, etc.
}

variable "project_name" {
  default = "LinkSnap-DevOps"
}

variable "ami_id" {
  description = "AMI for Ubuntu 22.04 LTS (Update this for your region!)"
  # This is for eu-west-1 (London). If you are in us-east-1, use: ami-0fc5d935ebf8bc3bc
  default     = "ami-053a617c6207ecc7b" 
}

variable "key_name" {
  description = "Name of the SSH key pair in AWS"
  default     = "cba_keypair" # Use your own keypair here
}