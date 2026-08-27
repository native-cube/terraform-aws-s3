resource "aws_s3_bucket" "main" {
  count = var.create_bucket ? 1 : 0

  region              = var.region
  bucket              = var.use_bucket_prefix ? null : var.bucket_name
  bucket_namespace    = var.bucket_namespace
  bucket_prefix       = var.use_bucket_prefix ? var.bucket_prefix : null
  force_destroy       = var.force_destroy
  object_lock_enabled = var.object_lock_enabled || var.object_lock_configuration != null
  tags                = local.common_tags
}

resource "aws_s3_directory_bucket" "main" {
  count = var.create_directory_bucket ? 1 : 0

  region          = var.region
  bucket          = var.directory_bucket_name
  data_redundancy = var.data_redundancy
  force_destroy   = var.force_destroy
  type            = "Directory"
  tags            = local.common_tags

  dynamic "location" {
    for_each = var.location_name == null ? [] : [var.location_name]

    content {
      name = location.value
      type = var.location_type
    }
  }

  lifecycle {
    precondition {
      condition     = var.directory_bucket_name != null
      error_message = "directory_bucket_name must be set when create_directory_bucket is true."
    }

    precondition {
      condition     = var.location_name != null
      error_message = "location_name must be set when create_directory_bucket is true."
    }
  }
}
