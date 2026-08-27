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

module "s3_access_point" {
  source = "../.."

  bucket_prefix     = var.bucket_prefix
  use_bucket_prefix = true

  enable_access_points = true
  access_points = [{
    name   = var.access_point_name
    vpc_id = var.vpc_id
    tags = {
      Purpose = "application-ingress"
    }
  }]

  tags = var.tags
}
