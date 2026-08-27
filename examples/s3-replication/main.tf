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

module "s3_replication" {
  source = "../.."

  bucket_prefix     = var.bucket_prefix
  use_bucket_prefix = true
  versioning        = "Enabled"

  enable_replication_configuration = true
  replication_configuration = {
    role = var.replication_role_arn
    rule = [{
      id       = "replicate-all"
      status   = "Enabled"
      priority = 1
      filter = {
        prefix = ""
      }
      delete_marker_replication = {
        status = "Enabled"
      }
      existing_object_replication = {
        status = "Enabled"
      }
      destination = {
        bucket        = var.destination_bucket_arn
        storage_class = "STANDARD"
      }
    }]
  }

  tags = var.tags
}
