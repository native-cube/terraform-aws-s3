locals {
  common_tags = var.tags

  access_points = var.enable_access_points ? {
    for access_point in var.access_points : access_point.name => access_point
  } : {}

  analytics_configurations           = var.create_bucket ? var.analytics_configurations : {}
  intelligent_tiering_configurations = var.create_bucket ? var.intelligent_tiering_configurations : {}
  inventory_configurations           = var.create_bucket ? var.inventory_configurations : {}
  metric_configurations              = var.create_bucket ? var.metric_configurations : {}

  lifecycle_rules = [
    for rule in var.lifecycle_rules : {
      configuration = rule
      filter_tags = merge(
        coalesce(try(rule.filter.tags, null), {}),
        try(rule.filter.tag, null) == null ? {} : { (rule.filter.tag.key) = rule.filter.tag.value }
      )
      filter_use_and = rule.filter != null && (
        length(merge(
          coalesce(try(rule.filter.tags, null), {}),
          try(rule.filter.tag, null) == null ? {} : { (rule.filter.tag.key) = rule.filter.tag.value }
        )) > 1 ||
        (
          (try(rule.filter.prefix, null) == null ? 0 : 1) +
          (length(merge(
            coalesce(try(rule.filter.tags, null), {}),
            try(rule.filter.tag, null) == null ? {} : { (rule.filter.tag.key) = rule.filter.tag.value }
          )) > 0 ? 1 : 0) +
          (try(rule.filter.object_size_greater_than, null) == null ? 0 : 1) +
          (try(rule.filter.object_size_less_than, null) == null ? 0 : 1)
        ) > 1
      )
    }
  ]
}
