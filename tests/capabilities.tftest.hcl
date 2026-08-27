mock_provider "aws" {
  override_during = plan
}

run "general_bucket_capabilities" {
  command = plan

  variables {
    bucket_name = "unit-capabilities"
    versioning  = "Enabled"

    sse_algorithm     = "aws:kms"
    kms_key_id        = "arn:aws:kms:eu-west-2:111122223333:key/00000000-0000-0000-0000-000000000000"
    enable_bucket_key = true

    configure_policy = true
    bucket_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = ["arn:aws:s3:::unit-capabilities", "arn:aws:s3:::unit-capabilities/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      }]
    })

    cors_rules = [{
      id              = "browser"
      allowed_methods = ["GET", "PUT"]
      allowed_origins = ["https://www.example.com"]
    }]

    lifecycle_rules = [{
      id     = "archive"
      status = "Enabled"
      filter = {
        tag = {
          key   = "data_class"
          value = "archive"
        }
      }
      transition = [{
        days          = 30
        storage_class = "STANDARD_IA"
      }]
      noncurrent_version_expiration = {
        noncurrent_days = 90
      }
    }]

    enable_s3_notification = true
    eventbridge            = true
    sqs_notifications = [{
      id        = "queue"
      queue_arn = "arn:aws:sqs:eu-west-2:111122223333:unit-events"
      events    = ["s3:ObjectCreated:*"]
    }]

    enable_website_configuration = true
    index_document               = "index.html"
    error_document               = "error.html"

    enable_access_points = true
    access_points = [{
      name   = "application"
      vpc_id = "vpc-0123456789abcdef0"
    }]
  }

  assert {
    condition = (
      aws_s3_bucket_versioning.main[0].versioning_configuration[0].status == "Enabled" &&
      one(aws_s3_bucket_server_side_encryption_configuration.main[0].rule).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms" &&
      one(aws_s3_bucket_server_side_encryption_configuration.main[0].rule).bucket_key_enabled
    )
    error_message = "Versioning and KMS encryption should use the requested configuration."
  }

  assert {
    condition = (
      length(aws_s3_bucket_policy.main) == 1 &&
      length(aws_s3_bucket_cors_configuration.main) == 1 &&
      length(aws_s3_bucket_lifecycle_configuration.main) == 1 &&
      length(aws_s3_bucket_notification.main) == 1 &&
      length(aws_s3_bucket_website_configuration.main) == 1
    )
    error_message = "Requested bucket policies and integrations should each be created."
  }

  assert {
    condition = (
      aws_s3_bucket_notification.main[0].eventbridge &&
      aws_s3_bucket_notification.main[0].queue[0].queue_arn == "arn:aws:sqs:eu-west-2:111122223333:unit-events" &&
      aws_s3_bucket_website_configuration.main[0].index_document[0].suffix == "index.html"
    )
    error_message = "Notification and website blocks should preserve caller values."
  }

  assert {
    condition = (
      length(aws_s3_access_point.main) == 1 &&
      aws_s3_access_point.main["application"].vpc_configuration[0].vpc_id == "vpc-0123456789abcdef0" &&
      aws_s3_access_point.main["application"].public_access_block_configuration[0].block_public_policy
    )
    error_message = "The named access point should be VPC-scoped and block public policies."
  }
}

run "replication" {
  command = plan

  variables {
    bucket_name                      = "unit-replication"
    versioning                       = "Enabled"
    enable_replication_configuration = true
    replication_configuration = {
      role = "arn:aws:iam::111122223333:role/unit-s3-replication"
      rule = [{
        id       = "all-objects"
        status   = "Enabled"
        priority = 1
        filter   = { prefix = "" }
        existing_object_replication = {
          status = "Enabled"
        }
        destination = {
          bucket        = "arn:aws:s3:::unit-destination"
          storage_class = "STANDARD"
        }
      }]
    }
  }

  assert {
    condition = (
      aws_s3_bucket_replication_configuration.main[0].role == "arn:aws:iam::111122223333:role/unit-s3-replication" &&
      aws_s3_bucket_replication_configuration.main[0].rule[0].destination[0].bucket == "arn:aws:s3:::unit-destination" &&
      aws_s3_bucket_replication_configuration.main[0].rule[0].existing_object_replication[0].status == "Enabled"
    )
    error_message = "Replication should preserve the supplied IAM role and destination bucket."
  }
}

run "directory_bucket" {
  command = plan

  variables {
    create_bucket           = false
    create_directory_bucket = true
    directory_bucket_name   = "unit--euw2-az1--x-s3"
    location_name           = "euw2-az1"
    enable_access_points    = true
    access_points = [{
      name        = "directory"
      bucket_type = "directory"
    }]
  }

  assert {
    condition = (
      length(aws_s3_bucket.main) == 0 &&
      aws_s3_directory_bucket.main[0].bucket == "unit--euw2-az1--x-s3" &&
      aws_s3_directory_bucket.main[0].location[0].name == "euw2-az1" &&
      aws_s3_directory_bucket.main[0].location[0].type == "AvailabilityZone" &&
      aws_s3_access_point.main["directory"].bucket == "unit--euw2-az1--x-s3"
    )
    error_message = "Directory-only mode should create the requested bucket in the selected Availability Zone."
  }
}
