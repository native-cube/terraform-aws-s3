mock_provider "aws" {
  override_during = plan
}

run "invalid_encryption_algorithm" {
  command = plan

  variables {
    bucket_name   = "unit-invalid-encryption"
    sse_algorithm = "DES"
  }

  expect_failures = [var.sse_algorithm]
}

run "invalid_cors_method" {
  command = plan

  variables {
    bucket_name = "unit-invalid-cors"
    cors_rules = [{
      allowed_methods = ["PATCH"]
      allowed_origins = ["https://www.example.com"]
    }]
  }

  expect_failures = [var.cors_rules]
}

run "acl_requires_compatible_ownership" {
  command = plan

  variables {
    bucket_name = "unit-invalid-acl"
    enable_acl  = true
    acl         = "private"
  }

  expect_failures = [aws_s3_bucket_acl.main[0]]
}

run "replication_requires_versioning" {
  command = plan

  variables {
    bucket_name                      = "unit-invalid-replication"
    enable_replication_configuration = true
    replication_configuration = {
      role = "arn:aws:iam::111122223333:role/unit-s3-replication"
      rule = [{
        id     = "all-objects"
        status = "Enabled"
        destination = {
          bucket = "arn:aws:s3:::unit-destination"
        }
      }]
    }
  }

  expect_failures = [aws_s3_bucket_replication_configuration.main[0]]
}

run "website_requires_index_or_redirect" {
  command = plan

  variables {
    bucket_name                  = "unit-invalid-website"
    enable_website_configuration = true
  }

  expect_failures = [aws_s3_bucket_website_configuration.main[0]]
}

run "bucket_prefix_toggle_requires_prefix" {
  command = plan

  variables {
    use_bucket_prefix = true
  }

  expect_failures = [aws_s3_bucket.main[0]]
}

run "invalid_intelligent_tiering_days" {
  command = plan

  variables {
    bucket_name = "unit-invalid-tiering"
    intelligent_tiering_configurations = {
      archive = {
        tiering = [{
          access_tier = "ARCHIVE_ACCESS"
          days        = 30
        }]
      }
    }
  }

  expect_failures = [var.intelligent_tiering_configurations]
}

run "lifecycle_rule_requires_action" {
  command = plan

  variables {
    bucket_name = "unit-invalid-lifecycle"
    lifecycle_rules = [{
      id     = "no-action"
      status = "Enabled"
    }]
  }

  expect_failures = [var.lifecycle_rules]
}

run "metadata_retention_requires_valid_days" {
  command = plan

  variables {
    bucket_name = "unit-invalid-metadata-retention"
    metadata_configuration = {
      inventory_table_configuration = {}
      journal_table_configuration = {
        record_expiration = {
          expiration = "ENABLED"
          days       = 6
        }
      }
    }
  }

  expect_failures = [var.metadata_configuration]
}
