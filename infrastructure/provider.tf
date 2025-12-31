terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "linksnap-tf-state-bootstrap-cm" # Matches your bucket in backend_resources.tf
    key            = "global/s3/terraform.tfstate"            # The path inside the bucket
    region         = "eu-west-2"
    encrypt        = true

    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}


