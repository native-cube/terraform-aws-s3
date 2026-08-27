mock_provider "aws" {
  override_during = plan
}

run "provider_arguments_lifecycle_and_logging" {
  command = plan

  variables {
    bucket_name      = "unit-provider-arguments"
    bucket_namespace = "account-regional"

    blocked_encryption_types = ["SSE-C"]

    lifecycle_transition_default_minimum_object_size = "varies_by_storage_class"
    lifecycle_configuration_timeouts = {
      create = "20m"
      update = "30m"
    }
    lifecycle_rules = [{
      id     = "archive-tagged-data"
      status = "Enabled"
      filter = {
        prefix = "archive/"
        tags = {
          data_class = "cold"
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
    logging_bucket_name   = "unit-access-logs"
    logging_target_prefix = "s3/"
    logging_target_object_key_format = {
      partitioned_prefix = {
        partition_date_source = "EventTime"
      }
    }
  }

  assert {
    condition = (
      aws_s3_bucket.main[0].bucket_namespace == "account-regional" &&
      contains(one(aws_s3_bucket_server_side_encryption_configuration.main[0].rule).blocked_encryption_types, "SSE-C")
    )
    error_message = "The bucket namespace and blocked encryption types should be passed to the latest provider resources."
  }

  assert {
    condition = (
      aws_s3_bucket_lifecycle_configuration.main[0].transition_default_minimum_object_size == "varies_by_storage_class" &&
      one(aws_s3_bucket_lifecycle_configuration.main[0].rule).abort_incomplete_multipart_upload[0].days_after_initiation == 7 &&
      one(aws_s3_bucket_lifecycle_configuration.main[0].rule).filter[0].and[0].prefix == "archive/" &&
      one(aws_s3_bucket_lifecycle_configuration.main[0].rule).filter[0].and[0].tags["data_class"] == "cold"
    )
    error_message = "Lifecycle rules should support multipart cleanup and combined tag filters."
  }

  assert {
    condition = (
      aws_s3_bucket_logging.main[0].target_prefix == "s3/" &&
      aws_s3_bucket_logging.main[0].target_object_key_format[0].partitioned_prefix[0].partition_date_source == "EventTime"
    )
    error_message = "Server access logging should preserve the selected target prefix and partitioned key format."
  }
}

run "object_lock_retention" {
  command = plan

  variables {
    bucket_name = "unit-object-lock"
    versioning  = "Enabled"
    object_lock_configuration = {
      default_retention = {
        mode = "GOVERNANCE"
        days = 30
      }
    }
  }

  assert {
    condition = (
      aws_s3_bucket.main[0].object_lock_enabled &&
      aws_s3_bucket_object_lock_configuration.main[0].object_lock_enabled == "Enabled" &&
      aws_s3_bucket_object_lock_configuration.main[0].rule[0].default_retention[0].mode == "GOVERNANCE" &&
      aws_s3_bucket_object_lock_configuration.main[0].rule[0].default_retention[0].days == 30
    )
    error_message = "Object Lock configuration should enable Object Lock at bucket creation and preserve the default retention rule."
  }
}

run "management_configurations_abac_and_metadata" {
  command = plan

  variables {
    bucket_name = "unit-data-management"
    abac_status = "Enabled"

    intelligent_tiering_configurations = {
      archive = {
        filter = {
          prefix = "documents/"
          tags   = { managed = "true" }
        }
        tiering = [{
          access_tier = "ARCHIVE_ACCESS"
          days        = 90
        }]
      }
    }

    inventory_configurations = {
      daily = {
        included_object_versions = "Current"
        optional_fields          = ["ETag", "StorageClass"]
        filter_prefix            = "documents/"
        destination = {
          bucket_arn = "arn:aws:s3:::unit-inventory-destination"
          prefix     = "inventory/"
          encryption = {
            sse_s3 = true
          }
        }
      }
    }

    analytics_configurations = {
      storage = {
        filter = {
          prefix = "documents/"
        }
        storage_class_analysis = {
          destination = {
            bucket_arn = "arn:aws:s3:::unit-analytics-destination"
            prefix     = "analytics/"
          }
        }
      }
    }

    metric_configurations = {
      requests = {
        filter = {
          prefix = "documents/"
          tags   = { managed = "true" }
        }
      }
    }

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
  }

  assert {
    condition = (
      aws_s3_bucket_abac.main[0].abac_status[0].status == "Enabled" &&
      one(aws_s3_bucket_intelligent_tiering_configuration.main["archive"].tiering).access_tier == "ARCHIVE_ACCESS" &&
      aws_s3_bucket_inventory.main["daily"].schedule[0].frequency == "Daily" &&
      length(aws_s3_bucket_inventory.main["daily"].destination[0].bucket[0].encryption[0].sse_s3) == 1
    )
    error_message = "ABAC, Intelligent-Tiering, and Inventory should preserve the requested settings."
  }

  assert {
    condition = (
      aws_s3_bucket_analytics_configuration.main["storage"].storage_class_analysis[0].data_export[0].destination[0].s3_bucket_destination[0].bucket_arn == "arn:aws:s3:::unit-analytics-destination" &&
      aws_s3_bucket_metric.main["requests"].filter[0].prefix == "documents/" &&
      aws_s3_bucket_metadata_configuration.main[0].metadata_configuration[0].inventory_table_configuration[0].configuration_state == "ENABLED" &&
      aws_s3_bucket_metadata_configuration.main[0].metadata_configuration[0].journal_table_configuration[0].record_expiration[0].days == 30
    )
    error_message = "Analytics, metrics, and S3 Metadata tables should preserve the requested settings."
  }
}

run "access_point_details_output" {
  command = plan

  variables {
    bucket_name          = "unit-access-point-output"
    enable_access_points = true
    access_points = [{
      name              = "application"
      account_id        = "111122223333"
      bucket_account_id = "111122223333"
    }]
  }

  override_resource {
    target          = aws_s3_access_point.main["application"]
    override_during = plan
    values = {
      alias          = "application-000000000000-s3alias"
      arn            = "arn:aws:s3:eu-west-2:111122223333:accesspoint/application"
      domain_name    = "application-000000000000.s3-accesspoint.eu-west-2.amazonaws.com"
      endpoints      = { ipv4 = "s3-accesspoint.eu-west-2.amazonaws.com" }
      id             = "application"
      network_origin = "Internet"
    }
  }

  assert {
    condition = (
      output.access_points["application"].arn == "arn:aws:s3:eu-west-2:111122223333:accesspoint/application" &&
      output.access_points["application"].network_origin == "Internet" &&
      aws_s3_access_point.main["application"].account_id == "111122223333" &&
      aws_s3_access_point.main["application"].bucket_account_id == "111122223333"
    )
    error_message = "The access point details output and account arguments should preserve the resource values."
  }
}
