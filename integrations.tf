resource "aws_s3_bucket_cors_configuration" "main" {
  count = var.create_bucket && length(var.cors_rules) > 0 ? 1 : 0

  region = var.region
  bucket = aws_s3_bucket.main[0].id

  dynamic "cors_rule" {
    for_each = var.cors_rules

    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      id              = try(cors_rule.value.id, null)
      max_age_seconds = try(cors_rule.value.max_age_seconds, null)
    }
  }
}

resource "aws_s3_bucket_logging" "main" {
  count = var.create_bucket && var.logging_enabled ? 1 : 0

  region        = var.region
  bucket        = aws_s3_bucket.main[0].id
  target_bucket = var.logging_bucket_name
  target_prefix = coalesce(var.logging_target_prefix, "logs/${aws_s3_bucket.main[0].id}/")

  dynamic "target_object_key_format" {
    for_each = var.logging_target_object_key_format == null ? [] : [var.logging_target_object_key_format]

    content {
      dynamic "partitioned_prefix" {
        for_each = target_object_key_format.value.partitioned_prefix == null ? [] : [target_object_key_format.value.partitioned_prefix]

        content {
          partition_date_source = partitioned_prefix.value.partition_date_source
        }
      }

      dynamic "simple_prefix" {
        for_each = target_object_key_format.value.simple_prefix ? [true] : []

        content {}
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.logging_bucket_name != null
      error_message = "logging_bucket_name must be set when logging_enabled is true."
    }
  }
}

resource "aws_s3_bucket_notification" "main" {
  count = var.create_bucket && var.enable_s3_notification ? 1 : 0

  region      = var.region
  bucket      = aws_s3_bucket.main[0].id
  eventbridge = var.eventbridge

  dynamic "lambda_function" {
    for_each = var.lambda_notifications

    content {
      events              = lambda_function.value.events
      filter_prefix       = try(lambda_function.value.filter_prefix, null)
      filter_suffix       = try(lambda_function.value.filter_suffix, null)
      id                  = try(lambda_function.value.id, null)
      lambda_function_arn = lambda_function.value.lambda_function_arn
    }
  }

  dynamic "queue" {
    for_each = var.sqs_notifications

    content {
      events        = queue.value.events
      filter_prefix = try(queue.value.filter_prefix, null)
      filter_suffix = try(queue.value.filter_suffix, null)
      id            = try(queue.value.id, null)
      queue_arn     = queue.value.queue_arn
    }
  }

  dynamic "topic" {
    for_each = var.sns_notifications

    content {
      events        = topic.value.events
      filter_prefix = try(topic.value.filter_prefix, null)
      filter_suffix = try(topic.value.filter_suffix, null)
      id            = try(topic.value.id, null)
      topic_arn     = topic.value.topic_arn
    }
  }
}
