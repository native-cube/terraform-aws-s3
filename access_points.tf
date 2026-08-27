resource "aws_s3_access_point" "main" {
  for_each = local.access_points

  region            = var.region
  account_id        = try(each.value.account_id, null)
  bucket            = each.value.bucket_type == "directory" ? try(aws_s3_directory_bucket.main[0].bucket, "") : try(aws_s3_bucket.main[0].id, "")
  bucket_account_id = try(each.value.bucket_account_id, null)
  name              = each.value.name
  policy            = try(each.value.policy, null)
  tags              = merge(local.common_tags, coalesce(try(each.value.tags, null), {}))

  public_access_block_configuration {
    block_public_acls       = each.value.block_public_acls
    block_public_policy     = each.value.block_public_policy
    ignore_public_acls      = each.value.ignore_public_acls
    restrict_public_buckets = each.value.restrict_public_buckets
  }

  dynamic "vpc_configuration" {
    for_each = each.value.vpc_id == null ? [] : [each.value.vpc_id]

    content {
      vpc_id = vpc_configuration.value
    }
  }

  lifecycle {
    precondition {
      condition = (
        (each.value.bucket_type == "general" && var.create_bucket) ||
        (each.value.bucket_type == "directory" && var.create_directory_bucket)
      )
      error_message = "Each access point bucket_type must refer to a bucket created by this module."
    }
  }
}
