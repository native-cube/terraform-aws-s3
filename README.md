# Terraform AWS S3 Module

[![Terraform Checks](https://github.com/native-cube/terraform-aws-s3/actions/workflows/terraform-pr.yml/badge.svg)](https://github.com/native-cube/terraform-aws-s3/actions/workflows/terraform-pr.yml)

Terraform module for creating production-oriented Amazon S3 resources. The module is implemented directly with HashiCorp AWS provider resources and does not wrap another S3 module.

The module supports:

- General purpose S3 buckets, including global and account-regional namespaces, and S3 Express One Zone directory buckets
- AES256, AWS KMS, and dual-layer AWS KMS server-side encryption, with optional SSE-C upload blocking
- Public access blocking, object ownership controls, optional ACLs, bucket policies, and bucket ABAC
- Versioning, Object Lock default retention, lifecycle rules, server access logging, and replication
- Intelligent-Tiering, Inventory, Analytics, request metrics, and S3 Metadata tables
- CORS, EventBridge, Lambda, SNS, and SQS notifications
- Static website configuration and redirects
- Public or VPC-scoped S3 access points

The root module does not create KMS keys, IAM roles, notification destinations, destination buckets, VPCs, or provider configuration. Callers supply those dependencies when enabling the related capability.

## Usage

```hcl
module "artifacts" {
  source  = "native-cube/s3/aws"
  version = "~> 1.0"

  bucket_name = "acme-production-artifacts"
  versioning  = "Enabled"

  sse_algorithm     = "aws:kms"
  kms_key_id        = var.artifacts_kms_key_arn
  enable_bucket_key = true

  lifecycle_rules = [{
    id     = "archive"
    status = "Enabled"
    filter = {
      prefix = "releases/"
    }
    transition = [{
      days          = 30
      storage_class = "STANDARD_IA"
    }]
    noncurrent_version_expiration = {
      noncurrent_days = 90
    }
  }]

  tags = {
    Environment = "production"
    Service     = "artifacts"
  }
}
```

## Compatibility and Versioning

Version 1.x requires Terraform 1.5 or newer and HashiCorp AWS provider 6.61 or newer within major version 6. The minimum and latest supported combinations are exercised separately in CI.

This module follows semantic versioning. Pin a compatible module version in production and review [CHANGELOG.md](CHANGELOG.md) before upgrading. Major releases may contain breaking changes; minor and patch releases preserve the documented 1.x interface.

## Security and Operations

- Server-side encryption is always configured for a general purpose bucket. AES256 is the default; select `aws:kms` or `aws:kms:dsse` to use an optional caller-managed KMS key.
- All four public-access-block settings default to `true`, ownership defaults to `BucketOwnerEnforced`, and ACL management is disabled. To use an ACL, explicitly enable it, select compatible object ownership, and provide exactly one canned or detailed ACL.
- `force_destroy` defaults to `false`. Enabling it allows Terraform to delete bucket contents during destroy, and those objects are not recoverable; Object Lock retention can still prevent deletion.
- Bucket policy JSON is validated syntactically, but callers remain responsible for least-privilege statements and correct principals, resources, and conditions.
- Set `blocked_encryption_types = ["SSE-C"]` to reject uploads encrypted with customer-provided keys while retaining the module's configured bucket-default encryption.
- Object Lock must be enabled when the bucket is created. Setting `object_lock_configuration` enables it automatically and supports `GOVERNANCE` or `COMPLIANCE` default retention in days or years. Per-object retention and legal holds remain caller responsibilities.

## Data Management and Observability

- Lifecycle rules support prefix, single-tag, multi-tag, and object-size filters; incomplete multipart upload cleanup; current-object transitions and expiration; and noncurrent-version transitions and expiration.
- Intelligent-Tiering, Inventory, Analytics, and request metrics use maps keyed by stable configuration names, so individual configurations have stable Terraform addresses.
- Inventory and Analytics destination buckets and their policies are caller managed. S3 Metadata availability, account prerequisites, and supported Regions should be confirmed before enabling `metadata_configuration`.
- `abac_status = "Enabled"` enables bucket attribute-based access control. Review existing IAM policies before adopting tag-based authorization.

## Replication and Integrations

- Replication, including existing-object replication, requires `versioning = "Enabled"`, an existing destination bucket with versioning enabled, and an IAM role that Amazon S3 can assume.
- Notification destination policies and Lambda invoke permissions are intentionally managed by callers. Configure them before applying the bucket notification resource.
- Access points inherit the module tags, block public access by default, can target the module's general purpose or directory bucket, and can optionally be restricted to an existing VPC.
- Website configuration does not make a bucket public. Prefer CloudFront with origin access control, or deliberately configure a tightly scoped bucket policy if direct S3 website access is required.
- Server access logging defaults to `logs/<source-bucket-name>/` in the caller-supplied logging bucket. The prefix and simple or date-partitioned object-key format are configurable; the destination bucket must permit S3 log delivery.

## Directory Buckets

Set `create_bucket = false` and `create_directory_bucket = true` for directory-only mode. Supply a location-specific `directory_bucket_name`, the matching Availability Zone or Local Zone ID in `location_name`, and the appropriate `location_type`. General purpose bucket features such as policies, lifecycle rules, notifications, and website hosting do not apply to directory buckets through this interface.

## Examples

- [`examples/s3-bucket`](examples/s3-bucket) - encrypted, versioned general purpose bucket.
- [`examples/s3-website`](examples/s3-website) - static website configuration with public access still blocked.
- [`examples/s3-cors`](examples/s3-cors) - browser upload and download CORS rule.
- [`examples/s3-notification`](examples/s3-notification) - EventBridge, Lambda, SNS, and SQS notifications.
- [`examples/s3-access-point`](examples/s3-access-point) - VPC-scoped S3 access point.
- [`examples/s3-directory-bucket`](examples/s3-directory-bucket) - S3 Express One Zone directory bucket.
- [`examples/s3-replication`](examples/s3-replication) - versioned replication source bucket.
- [`examples/s3-advanced`](examples/s3-advanced) - Object Lock, lifecycle cleanup, logging, data-management configurations, ABAC, and S3 Metadata.

## Development

Run `make check` to verify formatting, generated documentation, initialization, native Terraform tests, and every example. Run `make docs` after changing inputs, outputs, resources, or version constraints. `make release-check` additionally requires TFLint and Trivy and runs the complete pre-release gate. See [RELEASING.md](RELEASING.md) for the maintainer checklist.

## Module Documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.61.0, < 7.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.61.0, < 7.0.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_s3_access_point.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_access_point) | resource |
| [aws_s3_bucket.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_abac.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_abac) | resource |
| [aws_s3_bucket_acl.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_analytics_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_analytics_configuration) | resource |
| [aws_s3_bucket_cors_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | resource |
| [aws_s3_bucket_intelligent_tiering_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_intelligent_tiering_configuration) | resource |
| [aws_s3_bucket_inventory.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_inventory) | resource |
| [aws_s3_bucket_lifecycle_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_metadata_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_metadata_configuration) | resource |
| [aws_s3_bucket_metric.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_metric) | resource |
| [aws_s3_bucket_notification.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_object_lock_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration) | resource |
| [aws_s3_bucket_ownership_controls.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_replication_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_website_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration) | resource |
| [aws_s3_directory_bucket.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_directory_bucket) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_abac_status"></a> [abac\_status](#input\_abac\_status) | Optional attribute-based access control status for the general purpose bucket. Null leaves S3 bucket ABAC unmanaged. | `string` | `null` | no |
| <a name="input_access_control_policy"></a> [access\_control\_policy](#input\_access\_control\_policy) | Optional detailed access control policy for the general purpose bucket. Use this instead of acl when enable\_acl is true. | <pre>object({<br/>    owner = object({<br/>      id           = string<br/>      display_name = optional(string)<br/>    })<br/>    grant = list(object({<br/>      grantee = object({<br/>        type          = string<br/>        email_address = optional(string)<br/>        id            = optional(string)<br/>        uri           = optional(string)<br/>      })<br/>      permission = string<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_access_points"></a> [access\_points](#input\_access\_points) | S3 access points to create when enable\_access\_points is true. Access point names must be unique and may target the module-created general purpose or directory bucket. | <pre>list(object({<br/>    name                    = string<br/>    bucket_type             = optional(string, "general")<br/>    account_id              = optional(string)<br/>    bucket_account_id       = optional(string)<br/>    block_public_acls       = optional(bool, true)<br/>    block_public_policy     = optional(bool, true)<br/>    ignore_public_acls      = optional(bool, true)<br/>    restrict_public_buckets = optional(bool, true)<br/>    vpc_id                  = optional(string, null)<br/>    policy                  = optional(string, null)<br/>    tags                    = optional(map(string), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_acl"></a> [acl](#input\_acl) | Optional canned ACL to apply when enable\_acl is true. Conflicts with access\_control\_policy. | `string` | `null` | no |
| <a name="input_analytics_configurations"></a> [analytics\_configurations](#input\_analytics\_configurations) | S3 Analytics configurations for the general purpose bucket, keyed by a stable configuration name. | <pre>map(object({<br/>    filter = optional(object({<br/>      prefix = optional(string)<br/>      tags   = optional(map(string), {})<br/>    }))<br/>    storage_class_analysis = object({<br/>      output_schema_version = optional(string, "V_1")<br/>      destination = object({<br/>        bucket_account_id = optional(string)<br/>        bucket_arn        = string<br/>        format            = optional(string, "CSV")<br/>        prefix            = optional(string)<br/>      })<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_block_public_acls"></a> [block\_public\_acls](#input\_block\_public\_acls) | Whether Amazon S3 should block public ACLs for the general purpose bucket. | `bool` | `true` | no |
| <a name="input_block_public_policy"></a> [block\_public\_policy](#input\_block\_public\_policy) | Whether Amazon S3 should block public bucket policies for the general purpose bucket. | `bool` | `true` | no |
| <a name="input_blocked_encryption_types"></a> [blocked\_encryption\_types](#input\_blocked\_encryption\_types) | Optional server-side encryption types to reject for object uploads. Set to ["SSE-C"] to block customer-provided encryption keys; null leaves the provider default. | `set(string)` | `null` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the general purpose S3 bucket. When null, Amazon S3 generates a name unless bucket\_prefix is selected. | `string` | `null` | no |
| <a name="input_bucket_namespace"></a> [bucket\_namespace](#input\_bucket\_namespace) | Optional namespace for the general purpose bucket. Valid values are global and account-regional. Null uses the AWS global namespace default. | `string` | `null` | no |
| <a name="input_bucket_policy"></a> [bucket\_policy](#input\_bucket\_policy) | Optional S3 bucket policy JSON document used when configure\_policy is true. | `string` | `null` | no |
| <a name="input_bucket_prefix"></a> [bucket\_prefix](#input\_bucket\_prefix) | Prefix from which Amazon S3 generates the general purpose bucket name when use\_bucket\_prefix is true. | `string` | `null` | no |
| <a name="input_configure_policy"></a> [configure\_policy](#input\_configure\_policy) | Whether to attach bucket\_policy to the general purpose bucket. | `bool` | `false` | no |
| <a name="input_cors_rules"></a> [cors\_rules](#input\_cors\_rules) | Cross-Origin Resource Sharing rules for the general purpose bucket. | <pre>list(object({<br/>    allowed_methods = list(string)<br/>    allowed_origins = list(string)<br/>    allowed_headers = optional(list(string), [])<br/>    expose_headers  = optional(list(string), [])<br/>    max_age_seconds = optional(number)<br/>    id              = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_create_bucket"></a> [create\_bucket](#input\_create\_bucket) | Whether to create a general purpose S3 bucket. | `bool` | `true` | no |
| <a name="input_create_directory_bucket"></a> [create\_directory\_bucket](#input\_create\_directory\_bucket) | Whether to create an S3 directory bucket in addition to any general purpose bucket. | `bool` | `false` | no |
| <a name="input_data_redundancy"></a> [data\_redundancy](#input\_data\_redundancy) | Data redundancy for the directory bucket. | `string` | `"SingleAvailabilityZone"` | no |
| <a name="input_directory_bucket_name"></a> [directory\_bucket\_name](#input\_directory\_bucket\_name) | Name of the S3 directory bucket. The name must include the location-specific suffix required by Amazon S3. | `string` | `null` | no |
| <a name="input_enable_access_points"></a> [enable\_access\_points](#input\_enable\_access\_points) | Whether to create the access points declared in access\_points. | `bool` | `false` | no |
| <a name="input_enable_acl"></a> [enable\_acl](#input\_enable\_acl) | Whether to manage an ACL for the general purpose bucket. ACLs require an object ownership mode other than BucketOwnerEnforced. | `bool` | `false` | no |
| <a name="input_enable_bucket_key"></a> [enable\_bucket\_key](#input\_enable\_bucket\_key) | Whether to use an S3 Bucket Key for KMS-based server-side encryption. | `bool` | `false` | no |
| <a name="input_enable_replication_configuration"></a> [enable\_replication\_configuration](#input\_enable\_replication\_configuration) | Whether to configure replication for the general purpose bucket. | `bool` | `false` | no |
| <a name="input_enable_s3_notification"></a> [enable\_s3\_notification](#input\_enable\_s3\_notification) | Whether to manage EventBridge, Lambda, SNS, and SQS notifications for the general purpose bucket. | `bool` | `false` | no |
| <a name="input_enable_website_configuration"></a> [enable\_website\_configuration](#input\_enable\_website\_configuration) | Whether to configure static website hosting or redirection for the general purpose bucket. | `bool` | `false` | no |
| <a name="input_error_document"></a> [error\_document](#input\_error\_document) | Object key returned for website errors. | `string` | `null` | no |
| <a name="input_eventbridge"></a> [eventbridge](#input\_eventbridge) | Whether to send bucket events to Amazon EventBridge when notifications are enabled. | `bool` | `false` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Whether Terraform may delete bucket objects when destroying a bucket. Deleted objects are not recoverable, and Object Lock retention can still prevent deletion. | `bool` | `false` | no |
| <a name="input_ignore_public_acls"></a> [ignore\_public\_acls](#input\_ignore\_public\_acls) | Whether Amazon S3 should ignore public ACLs for the general purpose bucket. | `bool` | `true` | no |
| <a name="input_index_document"></a> [index\_document](#input\_index\_document) | Object suffix used as the website index document. | `string` | `null` | no |
| <a name="input_intelligent_tiering_configurations"></a> [intelligent\_tiering\_configurations](#input\_intelligent\_tiering\_configurations) | S3 Intelligent-Tiering configurations for the general purpose bucket, keyed by a stable configuration name. | <pre>map(object({<br/>    status = optional(string, "Enabled")<br/>    filter = optional(object({<br/>      prefix = optional(string)<br/>      tags   = optional(map(string), {})<br/>    }))<br/>    tiering = list(object({<br/>      access_tier = string<br/>      days        = number<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_inventory_configurations"></a> [inventory\_configurations](#input\_inventory\_configurations) | S3 Inventory configurations for the general purpose bucket, keyed by a stable configuration name. | <pre>map(object({<br/>    enabled                  = optional(bool, true)<br/>    included_object_versions = optional(string, "All")<br/>    optional_fields          = optional(set(string), [])<br/>    filter_prefix            = optional(string)<br/>    schedule_frequency       = optional(string, "Daily")<br/>    destination = object({<br/>      account_id = optional(string)<br/>      bucket_arn = string<br/>      format     = optional(string, "CSV")<br/>      prefix     = optional(string)<br/>      encryption = optional(object({<br/>        sse_kms = optional(object({<br/>          key_id = string<br/>        }))<br/>        sse_s3 = optional(bool, false)<br/>      }))<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | Optional KMS key ARN or ID used when sse\_algorithm is aws:kms or aws:kms:dsse. | `string` | `null` | no |
| <a name="input_lambda_notifications"></a> [lambda\_notifications](#input\_lambda\_notifications) | Lambda function notification destinations. Callers must grant Amazon S3 permission to invoke each function. | <pre>list(object({<br/>    lambda_function_arn = string<br/>    events              = list(string)<br/>    filter_prefix       = optional(string)<br/>    filter_suffix       = optional(string)<br/>    id                  = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_lifecycle_configuration_timeouts"></a> [lifecycle\_configuration\_timeouts](#input\_lifecycle\_configuration\_timeouts) | Optional create and update timeouts for the S3 lifecycle configuration. | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | Lifecycle rules for current and noncurrent objects in the general purpose bucket. | <pre>list(object({<br/>    id     = string<br/>    status = string<br/>    filter = optional(object({<br/>      object_size_greater_than = optional(string)<br/>      object_size_less_than    = optional(string)<br/>      prefix                   = optional(string)<br/>      tag = optional(object({<br/>        key   = string<br/>        value = string<br/>      }))<br/>      tags = optional(map(string))<br/>    }))<br/>    abort_incomplete_multipart_upload = optional(object({<br/>      days_after_initiation = number<br/>    }))<br/>    expiration = optional(object({<br/>      days                         = optional(number)<br/>      date                         = optional(string)<br/>      expired_object_delete_marker = optional(bool)<br/>    }))<br/>    transition = optional(list(object({<br/>      days          = optional(number)<br/>      date          = optional(string)<br/>      storage_class = string<br/>    })))<br/>    noncurrent_version_expiration = optional(object({<br/>      noncurrent_days           = number<br/>      newer_noncurrent_versions = optional(number)<br/>    }))<br/>    noncurrent_version_transition = optional(list(object({<br/>      noncurrent_days           = number<br/>      storage_class             = string<br/>      newer_noncurrent_versions = optional(number)<br/>    })))<br/>  }))</pre> | `[]` | no |
| <a name="input_lifecycle_transition_default_minimum_object_size"></a> [lifecycle\_transition\_default\_minimum\_object\_size](#input\_lifecycle\_transition\_default\_minimum\_object\_size) | Optional default minimum object-size behavior for lifecycle transitions. | `string` | `null` | no |
| <a name="input_location_name"></a> [location\_name](#input\_location\_name) | Availability Zone ID or Local Zone ID in which to create the directory bucket. | `string` | `null` | no |
| <a name="input_location_type"></a> [location\_type](#input\_location\_type) | Location type for the directory bucket. | `string` | `"AvailabilityZone"` | no |
| <a name="input_logging_bucket_name"></a> [logging\_bucket\_name](#input\_logging\_bucket\_name) | Destination bucket name for S3 server access logs. | `string` | `null` | no |
| <a name="input_logging_enabled"></a> [logging\_enabled](#input\_logging\_enabled) | Whether to deliver server access logs for the general purpose bucket. | `bool` | `false` | no |
| <a name="input_logging_target_object_key_format"></a> [logging\_target\_object\_key\_format](#input\_logging\_target\_object\_key\_format) | Optional server access log object-key format. Set exactly one partitioned\_prefix or simple\_prefix option. Null uses the S3 default simple format. | <pre>object({<br/>    partitioned_prefix = optional(object({<br/>      partition_date_source = optional(string, "EventTime")<br/>    }))<br/>    simple_prefix = optional(bool, false)<br/>  })</pre> | `null` | no |
| <a name="input_logging_target_prefix"></a> [logging\_target\_prefix](#input\_logging\_target\_prefix) | Optional prefix for server access log object keys. Null uses logs/<source-bucket-name>/. | `string` | `null` | no |
| <a name="input_metadata_configuration"></a> [metadata\_configuration](#input\_metadata\_configuration) | Optional S3 Metadata inventory and journal table configuration for the general purpose bucket. | <pre>object({<br/>    inventory_table_configuration = object({<br/>      configuration_state = optional(string, "ENABLED")<br/>      encryption_configuration = optional(object({<br/>        sse_algorithm = string<br/>        kms_key_arn   = optional(string)<br/>      }))<br/>    })<br/>    journal_table_configuration = object({<br/>      encryption_configuration = optional(object({<br/>        sse_algorithm = string<br/>        kms_key_arn   = optional(string)<br/>      }))<br/>      record_expiration = object({<br/>        expiration = optional(string, "ENABLED")<br/>        days       = optional(number)<br/>      })<br/>    })<br/>    create_timeout = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_metric_configurations"></a> [metric\_configurations](#input\_metric\_configurations) | S3 request metrics configurations for the general purpose bucket, keyed by a stable configuration name. | <pre>map(object({<br/>    filter = optional(object({<br/>      access_point = optional(string)<br/>      prefix       = optional(string)<br/>      tags         = optional(map(string), {})<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_object_lock_configuration"></a> [object\_lock\_configuration](#input\_object\_lock\_configuration) | Optional Object Lock default retention configuration for the general purpose bucket. Requires versioning to be Enabled. | <pre>object({<br/>    token = optional(string)<br/>    default_retention = optional(object({<br/>      mode  = optional(string, "GOVERNANCE")<br/>      days  = optional(number)<br/>      years = optional(number)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_object_lock_enabled"></a> [object\_lock\_enabled](#input\_object\_lock\_enabled) | Whether to enable S3 Object Lock on the general purpose bucket at creation time. object\_lock\_configuration also enables it automatically. | `bool` | `false` | no |
| <a name="input_object_ownership"></a> [object\_ownership](#input\_object\_ownership) | Object ownership mode for the general purpose bucket. BucketOwnerEnforced disables ACLs. | `string` | `"BucketOwnerEnforced"` | no |
| <a name="input_redirect_all_requests_to"></a> [redirect\_all\_requests\_to](#input\_redirect\_all\_requests\_to) | Optional website redirect target. This conflicts with index, error, and routing rule configuration. | <pre>object({<br/>    host_name = string<br/>    protocol  = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Optional AWS Region in which the module manages S3 resources. Defaults to the Region configured by the caller's AWS provider. | `string` | `null` | no |
| <a name="input_replication_configuration"></a> [replication\_configuration](#input\_replication\_configuration) | Replication role and rules used when enable\_replication\_configuration is true. | <pre>object({<br/>    role  = string<br/>    token = optional(string)<br/>    rule = list(object({<br/>      id       = string<br/>      status   = string<br/>      priority = optional(number)<br/>      filter = optional(object({<br/>        tag = optional(object({<br/>          key   = string<br/>          value = string<br/>        }))<br/>        tags   = optional(map(any))<br/>        prefix = optional(string)<br/>      }))<br/>      delete_marker_replication = optional(object({<br/>        status = string<br/>      }))<br/>      existing_object_replication = optional(object({<br/>        status = string<br/>      }))<br/>      destination = object({<br/>        access_control_translation = optional(object({<br/>          owner = string<br/>        }))<br/>        account = optional(string)<br/>        bucket  = string<br/>        encryption_configuration = optional(object({<br/>          replica_kms_key_id = string<br/>        }))<br/>        metrics = optional(object({<br/>          status = string<br/>          event_threshold = optional(object({<br/>            minutes = number<br/>          }))<br/>        }))<br/>        replication_time = optional(object({<br/>          status = string<br/>          time = object({<br/>            minutes = number<br/>          })<br/>        }))<br/>        storage_class = optional(string)<br/>      })<br/>      source_selection_criteria = optional(object({<br/>        replica_modifications = optional(object({<br/>          status = string<br/>        }))<br/>        sse_kms_encrypted_objects = optional(object({<br/>          status = string<br/>        }))<br/>      }))<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_restrict_public_buckets"></a> [restrict\_public\_buckets](#input\_restrict\_public\_buckets) | Whether Amazon S3 should restrict public bucket policies for the general purpose bucket. | `bool` | `true` | no |
| <a name="input_routing_rule"></a> [routing\_rule](#input\_routing\_rule) | Structured website routing rules. Use this or routing\_rules, but not both. | <pre>list(object({<br/>    condition = object({<br/>      http_error_code_returned_equals = optional(string)<br/>      key_prefix_equals               = optional(string)<br/>    })<br/>    redirect = object({<br/>      host_name               = optional(string)<br/>      http_redirect_code      = optional(string)<br/>      protocol                = optional(string)<br/>      replace_key_prefix_with = optional(string)<br/>      replace_key_with        = optional(string)<br/>    })<br/>  }))</pre> | `[]` | no |
| <a name="input_routing_rules"></a> [routing\_rules](#input\_routing\_rules) | JSON-encoded website routing rules. Use an empty string when unused. Conflicts with routing\_rule. | `string` | `""` | no |
| <a name="input_sns_notifications"></a> [sns\_notifications](#input\_sns\_notifications) | SNS topic notification destinations. Callers must configure each topic policy to permit delivery from Amazon S3. | <pre>list(object({<br/>    topic_arn     = string<br/>    events        = list(string)<br/>    filter_prefix = optional(string)<br/>    filter_suffix = optional(string)<br/>    id            = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_sqs_notifications"></a> [sqs\_notifications](#input\_sqs\_notifications) | SQS queue notification destinations. Callers must configure each queue policy to permit delivery from Amazon S3. | <pre>list(object({<br/>    queue_arn     = string<br/>    events        = list(string)<br/>    filter_prefix = optional(string)<br/>    filter_suffix = optional(string)<br/>    id            = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_sse_algorithm"></a> [sse\_algorithm](#input\_sse\_algorithm) | Server-side encryption algorithm for the general purpose bucket. | `string` | `"AES256"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all module-created buckets and access points. | `map(string)` | `{}` | no |
| <a name="input_use_bucket_prefix"></a> [use\_bucket\_prefix](#input\_use\_bucket\_prefix) | Whether to generate the general purpose bucket name from bucket\_prefix instead of using bucket\_name. | `bool` | `false` | no |
| <a name="input_versioning"></a> [versioning](#input\_versioning) | Optional versioning status for the general purpose bucket: Enabled, Suspended, or Disabled. Null leaves versioning unmanaged. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_access_points"></a> [access\_points](#output\_access\_points) | Details for access points created by the module, keyed by access point name. |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | Amazon Resource Name (ARN) of the created general purpose S3 bucket, or null when creation is disabled. |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | Bucket domain name of the created general purpose S3 bucket, or null when creation is disabled. |
| <a name="output_bucket_hosted_zone_id"></a> [bucket\_hosted\_zone\_id](#output\_bucket\_hosted\_zone\_id) | Route 53 hosted zone ID of the created general purpose S3 bucket, or null when creation is disabled. |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | ID and name of the created general purpose S3 bucket, or null when creation is disabled. |
| <a name="output_bucket_region"></a> [bucket\_region](#output\_bucket\_region) | AWS Region of the created general purpose S3 bucket, or null when creation is disabled. |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | Regional domain name of the created general purpose S3 bucket, or null when creation is disabled. |
| <a name="output_directory_bucket_arn"></a> [directory\_bucket\_arn](#output\_directory\_bucket\_arn) | Amazon Resource Name (ARN) of the created S3 directory bucket, or null when creation is disabled. |
| <a name="output_directory_bucket_name"></a> [directory\_bucket\_name](#output\_directory\_bucket\_name) | Name of the created S3 directory bucket, or null when creation is disabled. |
| <a name="output_website_domain"></a> [website\_domain](#output\_website\_domain) | Domain of the configured S3 bucket website, or null when website configuration is disabled. |
| <a name="output_website_endpoint"></a> [website\_endpoint](#output\_website\_endpoint) | Endpoint of the configured S3 bucket website, or null when website configuration is disabled. |
<!-- END_TF_DOCS -->
