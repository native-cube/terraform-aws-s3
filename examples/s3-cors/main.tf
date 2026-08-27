terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.61.0, < 7.0.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "s3_cors" {
  source = "../.."

  bucket_prefix     = var.bucket_prefix
  use_bucket_prefix = true

  cors_rules = [{
    id              = "browser-uploads"
    allowed_methods = ["GET", "HEAD", "PUT"]
    allowed_origins = var.allowed_origins
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }]

  tags = var.tags
}
