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

module "s3_bucket" {
  source = "../.."

  bucket_prefix     = var.bucket_prefix
  use_bucket_prefix = true
  versioning        = "Enabled"

  tags = var.tags
}
