# 1. S3 Bucket to store the State File
resource "aws_s3_bucket" "terraform_state" {
  # UPDATE THIS NAME TO BE UNIQUE
  bucket = "linksnap-tf-state-bootstrap-cm" 
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_ver" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_enc" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}