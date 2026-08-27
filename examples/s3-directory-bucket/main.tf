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

module "s3_directory_bucket" {
  source = "../.."

  create_bucket           = false
  create_directory_bucket = true
  directory_bucket_name   = var.directory_bucket_name
  location_name           = var.location_name
  location_type           = var.location_type

  tags = var.tags
}
