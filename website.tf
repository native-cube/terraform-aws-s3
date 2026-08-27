resource "aws_s3_bucket_website_configuration" "main" {
  count = var.create_bucket && var.enable_website_configuration ? 1 : 0

  region        = var.region
  bucket        = aws_s3_bucket.main[0].id
  routing_rules = var.routing_rules == "" ? null : var.routing_rules

  dynamic "error_document" {
    for_each = var.error_document == null ? [] : [var.error_document]

    content {
      key = error_document.value
    }
  }

  dynamic "index_document" {
    for_each = var.index_document == null ? [] : [var.index_document]

    content {
      suffix = index_document.value
    }
  }

  dynamic "redirect_all_requests_to" {
    for_each = var.redirect_all_requests_to == null ? [] : [var.redirect_all_requests_to]

    content {
      host_name = redirect_all_requests_to.value.host_name
      protocol  = try(redirect_all_requests_to.value.protocol, null)
    }
  }

  dynamic "routing_rule" {
    for_each = var.routing_rule

    content {
      condition {
        http_error_code_returned_equals = try(routing_rule.value.condition.http_error_code_returned_equals, null)
        key_prefix_equals               = try(routing_rule.value.condition.key_prefix_equals, null)
      }

      redirect {
        host_name               = try(routing_rule.value.redirect.host_name, null)
        http_redirect_code      = try(routing_rule.value.redirect.http_redirect_code, null)
        protocol                = try(routing_rule.value.redirect.protocol, null)
        replace_key_prefix_with = try(routing_rule.value.redirect.replace_key_prefix_with, null)
        replace_key_with        = try(routing_rule.value.redirect.replace_key_with, null)
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.redirect_all_requests_to != null || var.index_document != null
      error_message = "Website configuration requires either redirect_all_requests_to or index_document."
    }

    precondition {
      condition = var.redirect_all_requests_to == null || (
        var.index_document == null &&
        var.error_document == null &&
        length(var.routing_rule) == 0 &&
        var.routing_rules == ""
      )
      error_message = "redirect_all_requests_to conflicts with index_document, error_document, routing_rule, and routing_rules."
    }

    precondition {
      condition     = length(var.routing_rule) == 0 || var.routing_rules == ""
      error_message = "Set only one of routing_rule or routing_rules."
    }
  }
}
