terraform {
  required_version = ">= 1.11.4"

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

module "s3_website" {
  source = "../.."

  bucket_prefix     = var.bucket_prefix
  use_bucket_prefix = true

  enable_website_configuration = true
  index_document               = "index.html"
  error_document               = "error.html"

  tags = var.tags
}
