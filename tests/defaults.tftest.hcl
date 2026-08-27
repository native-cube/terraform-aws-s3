mock_provider "aws" {
  override_during = plan
}

run "secure_general_bucket_defaults" {
  command = plan

  variables {
    bucket_name = "unit-secure-defaults"
  }

  assert {
    condition     = length(aws_s3_bucket.main) == 1 && aws_s3_bucket.main[0].bucket == "unit-secure-defaults"
    error_message = "The module should create the named general purpose bucket by default."
  }

  assert {
    condition = (
      aws_s3_bucket.main[0].force_destroy == false &&
      aws_s3_bucket.main[0].object_lock_enabled == false
    )
    error_message = "Destructive bucket deletion and Object Lock should be disabled by default."
  }

  assert {
    condition = (
      aws_s3_bucket_public_access_block.main[0].block_public_acls &&
      aws_s3_bucket_public_access_block.main[0].block_public_policy &&
      aws_s3_bucket_public_access_block.main[0].ignore_public_acls &&
      aws_s3_bucket_public_access_block.main[0].restrict_public_buckets
    )
    error_message = "All public-access-block protections should be enabled by default."
  }

  assert {
    condition = (
      aws_s3_bucket_ownership_controls.main[0].rule[0].object_ownership == "BucketOwnerEnforced" &&
      length(aws_s3_bucket_acl.main) == 0
    )
    error_message = "BucketOwnerEnforced ownership should disable ACL use by default."
  }

  assert {
    condition = (
      one(aws_s3_bucket_server_side_encryption_configuration.main[0].rule).apply_server_side_encryption_by_default[0].sse_algorithm == "AES256" &&
      one(aws_s3_bucket_server_side_encryption_configuration.main[0].rule).bucket_key_enabled == false
    )
    error_message = "Buckets should use AES256 server-side encryption by default."
  }

  assert {
    condition = (
      length(aws_s3_bucket_versioning.main) == 0 &&
      length(aws_s3_bucket_lifecycle_configuration.main) == 0 &&
      length(aws_s3_bucket_notification.main) == 0 &&
      length(aws_s3_bucket_website_configuration.main) == 0 &&
      length(aws_s3_directory_bucket.main) == 0 &&
      length(aws_s3_access_point.main) == 0 &&
      length(aws_s3_bucket_abac.main) == 0 &&
      length(aws_s3_bucket_object_lock_configuration.main) == 0 &&
      length(aws_s3_bucket_intelligent_tiering_configuration.main) == 0 &&
      length(aws_s3_bucket_inventory.main) == 0 &&
      length(aws_s3_bucket_analytics_configuration.main) == 0 &&
      length(aws_s3_bucket_metric.main) == 0 &&
      length(aws_s3_bucket_metadata_configuration.main) == 0
    )
    error_message = "Optional bucket capabilities should remain disabled until requested."
  }
}

run "bucket_prefix" {
  command = plan

  variables {
    use_bucket_prefix = true
    bucket_prefix     = "unit-prefix-"
  }

  assert {
    condition     = aws_s3_bucket.main[0].bucket_prefix == "unit-prefix-"
    error_message = "use_bucket_prefix should select bucket_prefix instead of bucket_name."
  }
}
