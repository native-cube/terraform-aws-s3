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

module "s3_advanced" {
  source = "../.."

  bucket_prefix     = var.bucket_prefix
  use_bucket_prefix = true
  bucket_namespace  = var.bucket_namespace
  versioning        = "Enabled"

  blocked_encryption_types = ["SSE-C"]

  object_lock_configuration = {
    default_retention = {
      mode = "GOVERNANCE"
      days = 30
    }
  }

  lifecycle_transition_default_minimum_object_size = "varies_by_storage_class"
  lifecycle_rules = [{
    id     = "archive-records"
    status = "Enabled"
    filter = {
      prefix = "records/"
      tags = {
        retention = "archive"
      }
    }
    abort_incomplete_multipart_upload = {
      days_after_initiation = 7
    }
    transition = [{
      days          = 30
      storage_class = "STANDARD_IA"
    }]
  }]

  logging_enabled       = true
  logging_bucket_name   = var.logging_bucket_name
  logging_target_prefix = "s3-access/"
  logging_target_object_key_format = {
    partitioned_prefix = {
      partition_date_source = "EventTime"
    }
  }

  intelligent_tiering_configurations = {
    records = {
      filter = {
        prefix = "records/"
      }
      tiering = [
        {
          access_tier = "ARCHIVE_ACCESS"
          days        = 90
        },
        {
          access_tier = "DEEP_ARCHIVE_ACCESS"
          days        = 180
        },
      ]
    }
  }

  inventory_configurations = {
    daily = {
      included_object_versions = "All"
      optional_fields          = ["ETag", "StorageClass"]
      filter_prefix            = "records/"
      destination = {
        bucket_arn = var.reporting_bucket_arn
        prefix     = "inventory/"
        encryption = {
          sse_s3 = true
        }
      }
    }
  }

  analytics_configurations = {
    records = {
      filter = {
        prefix = "records/"
      }
      storage_class_analysis = {
        destination = {
          bucket_arn = var.reporting_bucket_arn
          prefix     = "analytics/"
        }
      }
    }
  }

  metric_configurations = {
    records = {
      filter = {
        prefix = "records/"
      }
    }
  }

  abac_status = "Enabled"
  metadata_configuration = {
    inventory_table_configuration = {
      configuration_state = "ENABLED"
      encryption_configuration = {
        sse_algorithm = "AES256"
      }
    }
    journal_table_configuration = {
      encryption_configuration = {
        sse_algorithm = "AES256"
      }
      record_expiration = {
        expiration = "ENABLED"
        days       = 30
      }
    }
  }

  tags = var.tags
}
