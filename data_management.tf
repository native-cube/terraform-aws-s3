resource "aws_s3_bucket_versioning" "main" {
  count = var.create_bucket && var.versioning != null ? 1 : 0

  region = var.region
  bucket = aws_s3_bucket.main[0].id

  versioning_configuration {
    status = var.versioning
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count = var.create_bucket && length(var.lifecycle_rules) > 0 ? 1 : 0

  region                                 = var.region
  bucket                                 = aws_s3_bucket.main[0].id
  transition_default_minimum_object_size = var.lifecycle_transition_default_minimum_object_size

  dynamic "rule" {
    for_each = local.lifecycle_rules

    content {
      id     = rule.value.configuration.id
      status = rule.value.configuration.status

      filter {
        object_size_greater_than = rule.value.filter_use_and ? null : try(rule.value.configuration.filter.object_size_greater_than, null)
        object_size_less_than    = rule.value.filter_use_and ? null : try(rule.value.configuration.filter.object_size_less_than, null)
        prefix                   = rule.value.filter_use_and ? null : try(rule.value.configuration.filter.prefix, null)

        dynamic "tag" {
          for_each = !rule.value.filter_use_and && length(rule.value.filter_tags) == 1 ? [one(keys(rule.value.filter_tags))] : []

          content {
            key   = tag.value
            value = rule.value.filter_tags[tag.value]
          }
        }

        dynamic "and" {
          for_each = rule.value.filter_use_and ? [rule.value] : []

          content {
            object_size_greater_than = try(and.value.configuration.filter.object_size_greater_than, null)
            object_size_less_than    = try(and.value.configuration.filter.object_size_less_than, null)
            prefix                   = try(and.value.configuration.filter.prefix, null)
            tags                     = length(and.value.filter_tags) > 0 ? and.value.filter_tags : null
          }
        }
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.configuration.abort_incomplete_multipart_upload == null ? [] : [rule.value.configuration.abort_incomplete_multipart_upload]

        content {
          days_after_initiation = abort_incomplete_multipart_upload.value.days_after_initiation
        }
      }

      dynamic "expiration" {
        for_each = rule.value.configuration.expiration == null ? [] : [rule.value.configuration.expiration]

        content {
          date                         = try(expiration.value.date, null)
          days                         = try(expiration.value.days, null)
          expired_object_delete_marker = try(expiration.value.expired_object_delete_marker, null)
        }
      }

      dynamic "transition" {
        for_each = coalesce(rule.value.configuration.transition, [])

        content {
          date          = try(transition.value.date, null)
          days          = try(transition.value.days, null)
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.configuration.noncurrent_version_expiration == null ? [] : [rule.value.configuration.noncurrent_version_expiration]

        content {
          newer_noncurrent_versions = try(noncurrent_version_expiration.value.newer_noncurrent_versions, null)
          noncurrent_days           = noncurrent_version_expiration.value.noncurrent_days
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = coalesce(rule.value.configuration.noncurrent_version_transition, [])

        content {
          newer_noncurrent_versions = try(noncurrent_version_transition.value.newer_noncurrent_versions, null)
          noncurrent_days           = noncurrent_version_transition.value.noncurrent_days
          storage_class             = noncurrent_version_transition.value.storage_class
        }
      }
    }
  }

  timeouts {
    create = try(var.lifecycle_configuration_timeouts.create, null)
    update = try(var.lifecycle_configuration_timeouts.update, null)
  }

  depends_on = [aws_s3_bucket_versioning.main]
}

resource "aws_s3_bucket_object_lock_configuration" "main" {
  count = var.create_bucket && var.object_lock_configuration != null ? 1 : 0

  region              = var.region
  bucket              = aws_s3_bucket.main[0].id
  object_lock_enabled = "Enabled"
  token               = try(var.object_lock_configuration.token, null)

  dynamic "rule" {
    for_each = try(var.object_lock_configuration.default_retention, null) == null ? [] : [var.object_lock_configuration.default_retention]

    content {
      default_retention {
        days  = try(rule.value.days, null)
        mode  = rule.value.mode
        years = try(rule.value.years, null)
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]

  lifecycle {
    precondition {
      condition     = var.versioning == "Enabled"
      error_message = "versioning must be Enabled when object_lock_configuration is set."
    }
  }
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "main" {
  for_each = local.intelligent_tiering_configurations

  region = var.region
  bucket = aws_s3_bucket.main[0].id
  name   = each.key
  status = each.value.status

  dynamic "filter" {
    for_each = each.value.filter == null ? [] : [each.value.filter]

    content {
      prefix = try(filter.value.prefix, null)
      tags   = length(filter.value.tags) > 0 ? filter.value.tags : null
    }
  }

  dynamic "tiering" {
    for_each = each.value.tiering

    content {
      access_tier = tiering.value.access_tier
      days        = tiering.value.days
    }
  }
}

resource "aws_s3_bucket_inventory" "main" {
  for_each = local.inventory_configurations

  region                   = var.region
  bucket                   = aws_s3_bucket.main[0].id
  enabled                  = each.value.enabled
  included_object_versions = each.value.included_object_versions
  name                     = each.key
  optional_fields          = sort(tolist(each.value.optional_fields))

  destination {
    bucket {
      account_id = try(each.value.destination.account_id, null)
      bucket_arn = each.value.destination.bucket_arn
      format     = each.value.destination.format
      prefix     = try(each.value.destination.prefix, null)

      dynamic "encryption" {
        for_each = each.value.destination.encryption == null ? [] : [each.value.destination.encryption]

        content {
          dynamic "sse_kms" {
            for_each = encryption.value.sse_kms == null ? [] : [encryption.value.sse_kms]

            content {
              key_id = sse_kms.value.key_id
            }
          }

          dynamic "sse_s3" {
            for_each = encryption.value.sse_s3 ? [true] : []

            content {}
          }
        }
      }
    }
  }

  dynamic "filter" {
    for_each = each.value.filter_prefix == null ? [] : [each.value.filter_prefix]

    content {
      prefix = filter.value
    }
  }

  schedule {
    frequency = each.value.schedule_frequency
  }
}

resource "aws_s3_bucket_analytics_configuration" "main" {
  for_each = local.analytics_configurations

  region = var.region
  bucket = aws_s3_bucket.main[0].id
  name   = each.key

  dynamic "filter" {
    for_each = each.value.filter == null ? [] : [each.value.filter]

    content {
      prefix = try(filter.value.prefix, null)
      tags   = length(filter.value.tags) > 0 ? filter.value.tags : null
    }
  }

  storage_class_analysis {
    data_export {
      output_schema_version = each.value.storage_class_analysis.output_schema_version

      destination {
        s3_bucket_destination {
          bucket_account_id = try(each.value.storage_class_analysis.destination.bucket_account_id, null)
          bucket_arn        = each.value.storage_class_analysis.destination.bucket_arn
          format            = each.value.storage_class_analysis.destination.format
          prefix            = try(each.value.storage_class_analysis.destination.prefix, null)
        }
      }
    }
  }
}

resource "aws_s3_bucket_metric" "main" {
  for_each = local.metric_configurations

  region = var.region
  bucket = aws_s3_bucket.main[0].id
  name   = each.key

  dynamic "filter" {
    for_each = each.value.filter == null ? [] : [each.value.filter]

    content {
      access_point = try(filter.value.access_point, null)
      prefix       = try(filter.value.prefix, null)
      tags         = length(filter.value.tags) > 0 ? filter.value.tags : null
    }
  }
}

resource "aws_s3_bucket_metadata_configuration" "main" {
  count = var.create_bucket && var.metadata_configuration != null ? 1 : 0

  region = var.region
  bucket = aws_s3_bucket.main[0].id

  metadata_configuration {
    inventory_table_configuration {
      configuration_state = var.metadata_configuration.inventory_table_configuration.configuration_state

      dynamic "encryption_configuration" {
        for_each = var.metadata_configuration.inventory_table_configuration.encryption_configuration == null ? [] : [var.metadata_configuration.inventory_table_configuration.encryption_configuration]

        content {
          kms_key_arn   = try(encryption_configuration.value.kms_key_arn, null)
          sse_algorithm = encryption_configuration.value.sse_algorithm
        }
      }
    }

    journal_table_configuration {
      dynamic "encryption_configuration" {
        for_each = var.metadata_configuration.journal_table_configuration.encryption_configuration == null ? [] : [var.metadata_configuration.journal_table_configuration.encryption_configuration]

        content {
          kms_key_arn   = try(encryption_configuration.value.kms_key_arn, null)
          sse_algorithm = encryption_configuration.value.sse_algorithm
        }
      }

      record_expiration {
        days       = try(var.metadata_configuration.journal_table_configuration.record_expiration.days, null)
        expiration = var.metadata_configuration.journal_table_configuration.record_expiration.expiration
      }
    }
  }

  timeouts {
    create = try(var.metadata_configuration.create_timeout, null)
  }
}

resource "aws_s3_bucket_replication_configuration" "main" {
  count = var.create_bucket && var.enable_replication_configuration ? 1 : 0

  region = var.region
  bucket = aws_s3_bucket.main[0].id
  role   = try(var.replication_configuration.role, "")
  token  = try(var.replication_configuration.token, null)

  dynamic "rule" {
    for_each = try(var.replication_configuration.rule, [])

    content {
      id       = rule.value.id
      priority = try(rule.value.priority, null)
      status   = rule.value.status

      dynamic "filter" {
        for_each = rule.value.filter == null ? [] : [rule.value.filter]

        content {
          prefix = try(filter.value.tag, null) == null && try(filter.value.tags, null) == null ? try(filter.value.prefix, null) : null

          dynamic "tag" {
            for_each = try(filter.value.tag, null) == null ? [] : [filter.value.tag]

            content {
              key   = tag.value.key
              value = tag.value.value
            }
          }

          dynamic "and" {
            for_each = try(filter.value.tags, null) == null ? [] : [filter.value]

            content {
              prefix = try(and.value.prefix, null)
              tags   = { for key, value in and.value.tags : key => tostring(value) }
            }
          }
        }
      }

      dynamic "delete_marker_replication" {
        for_each = rule.value.delete_marker_replication == null ? [] : [rule.value.delete_marker_replication]

        content {
          status = delete_marker_replication.value.status
        }
      }

      dynamic "existing_object_replication" {
        for_each = rule.value.existing_object_replication == null ? [] : [rule.value.existing_object_replication]

        content {
          status = existing_object_replication.value.status
        }
      }

      destination {
        account       = try(rule.value.destination.account, null)
        bucket        = rule.value.destination.bucket
        storage_class = try(rule.value.destination.storage_class, null)

        dynamic "access_control_translation" {
          for_each = rule.value.destination.access_control_translation == null ? [] : [rule.value.destination.access_control_translation]

          content {
            owner = access_control_translation.value.owner
          }
        }

        dynamic "encryption_configuration" {
          for_each = rule.value.destination.encryption_configuration == null ? [] : [rule.value.destination.encryption_configuration]

          content {
            replica_kms_key_id = encryption_configuration.value.replica_kms_key_id
          }
        }

        dynamic "metrics" {
          for_each = rule.value.destination.metrics == null ? [] : [rule.value.destination.metrics]

          content {
            status = metrics.value.status

            dynamic "event_threshold" {
              for_each = metrics.value.event_threshold == null ? [] : [metrics.value.event_threshold]

              content {
                minutes = event_threshold.value.minutes
              }
            }
          }
        }

        dynamic "replication_time" {
          for_each = rule.value.destination.replication_time == null ? [] : [rule.value.destination.replication_time]

          content {
            status = replication_time.value.status

            time {
              minutes = replication_time.value.time.minutes
            }
          }
        }
      }

      dynamic "source_selection_criteria" {
        for_each = rule.value.source_selection_criteria == null ? [] : [rule.value.source_selection_criteria]

        content {
          dynamic "replica_modifications" {
            for_each = source_selection_criteria.value.replica_modifications == null ? [] : [source_selection_criteria.value.replica_modifications]

            content {
              status = replica_modifications.value.status
            }
          }

          dynamic "sse_kms_encrypted_objects" {
            for_each = source_selection_criteria.value.sse_kms_encrypted_objects == null ? [] : [source_selection_criteria.value.sse_kms_encrypted_objects]

            content {
              status = sse_kms_encrypted_objects.value.status
            }
          }
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]

  lifecycle {
    precondition {
      condition     = var.replication_configuration != null
      error_message = "replication_configuration must be set when enable_replication_configuration is true."
    }

    precondition {
      condition     = var.versioning == "Enabled"
      error_message = "versioning must be Enabled when replication is configured."
    }

    precondition {
      condition = var.replication_configuration == null ? true : alltrue([
        for rule in var.replication_configuration.rule :
        try(rule.filter.tag, null) == null || try(rule.filter.tags, null) == null
      ])
      error_message = "A replication rule filter can set tag or tags, but not both."
    }
  }
}
