resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = var.create_bucket ? 1 : 0

  region = var.region
  bucket = aws_s3_bucket.main[0].id

  rule {
    blocked_encryption_types = var.blocked_encryption_types == null ? null : sort(tolist(var.blocked_encryption_types))
    bucket_key_enabled       = var.enable_bucket_key

    apply_server_side_encryption_by_default {
      kms_master_key_id = contains(["aws:kms", "aws:kms:dsse"], var.sse_algorithm) ? var.kms_key_id : null
      sse_algorithm     = var.sse_algorithm
    }
  }

  lifecycle {
    precondition {
      condition     = var.kms_key_id == null || contains(["aws:kms", "aws:kms:dsse"], var.sse_algorithm)
      error_message = "kms_key_id can be set only when sse_algorithm is aws:kms or aws:kms:dsse."
    }

    precondition {
      condition     = !var.enable_bucket_key || var.sse_algorithm == "aws:kms"
      error_message = "enable_bucket_key can be true only with sse_algorithm = aws:kms; S3 Bucket Keys do not support dual-layer aws:kms:dsse encryption."
    }
  }
}

resource "aws_s3_bucket_abac" "main" {
  count = var.create_bucket && var.abac_status != null ? 1 : 0

  region = var.region
  bucket = aws_s3_bucket.main[0].id

  abac_status {
    status = var.abac_status
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  count = var.create_bucket ? 1 : 0

  region                  = var.region
  bucket                  = aws_s3_bucket.main[0].id
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

resource "aws_s3_bucket_ownership_controls" "main" {
  count = var.create_bucket ? 1 : 0

  region = var.region
  bucket = aws_s3_bucket.main[0].id

  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_s3_bucket_acl" "main" {
  count = var.create_bucket && var.enable_acl ? 1 : 0

  region = var.region
  bucket = aws_s3_bucket.main[0].id
  acl    = var.access_control_policy == null ? var.acl : null

  dynamic "access_control_policy" {
    for_each = var.access_control_policy == null ? [] : [var.access_control_policy]

    content {
      dynamic "grant" {
        for_each = access_control_policy.value.grant

        content {
          permission = grant.value.permission

          grantee {
            email_address = try(grant.value.grantee.email_address, null)
            id            = try(grant.value.grantee.id, null)
            type          = grant.value.grantee.type
            uri           = try(grant.value.grantee.uri, null)
          }
        }
      }

      owner {
        display_name = try(access_control_policy.value.owner.display_name, null)
        id           = access_control_policy.value.owner.id
      }
    }
  }

  depends_on = [
    aws_s3_bucket_ownership_controls.main,
    aws_s3_bucket_public_access_block.main,
  ]

  lifecycle {
    precondition {
      condition     = var.object_ownership != "BucketOwnerEnforced"
      error_message = "enable_acl is incompatible with object_ownership = BucketOwnerEnforced because that ownership mode disables ACLs."
    }

    precondition {
      condition     = (var.acl == null) != (var.access_control_policy == null)
      error_message = "Set exactly one of acl or access_control_policy when enable_acl is true."
    }
  }
}

resource "aws_s3_bucket_policy" "main" {
  count = var.create_bucket && var.configure_policy ? 1 : 0

  region = var.region
  bucket = aws_s3_bucket.main[0].id
  policy = var.bucket_policy

  depends_on = [aws_s3_bucket_public_access_block.main]

  lifecycle {
    precondition {
      condition     = var.bucket_policy != null
      error_message = "bucket_policy must be set when configure_policy is true."
    }
  }
}
