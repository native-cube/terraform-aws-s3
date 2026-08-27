variable "abac_status" {
  description = "Optional attribute-based access control status for the general purpose bucket. Null leaves S3 bucket ABAC unmanaged."
  type        = string
  default     = null

  validation {
    condition     = var.abac_status == null ? true : contains(["Disabled", "Enabled"], var.abac_status)
    error_message = "abac_status must be null, Disabled, or Enabled."
  }
}

variable "access_control_policy" {
  description = "Optional detailed access control policy for the general purpose bucket. Use this instead of acl when enable_acl is true."
  type = object({
    owner = object({
      id           = string
      display_name = optional(string)
    })
    grant = list(object({
      grantee = object({
        type          = string
        email_address = optional(string)
        id            = optional(string)
        uri           = optional(string)
      })
      permission = string
    }))
  })
  default = null

  validation {
    condition = var.access_control_policy == null ? true : (
      trimspace(var.access_control_policy.owner.id) != "" &&
      alltrue([
        for grant in var.access_control_policy.grant :
        contains(["FULL_CONTROL", "READ", "READ_ACP", "WRITE", "WRITE_ACP"], grant.permission) &&
        contains(["AmazonCustomerByEmail", "CanonicalUser", "Group"], grant.grantee.type)
      ])
    )
    error_message = "access_control_policy must have a non-empty owner ID and use supported S3 grantee types and permissions."
  }
}

variable "access_points" {
  description = "S3 access points to create when enable_access_points is true. Access point names must be unique and may target the module-created general purpose or directory bucket."
  type = list(object({
    name                    = string
    bucket_type             = optional(string, "general")
    account_id              = optional(string)
    bucket_account_id       = optional(string)
    block_public_acls       = optional(bool, true)
    block_public_policy     = optional(bool, true)
    ignore_public_acls      = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
    vpc_id                  = optional(string, null)
    policy                  = optional(string, null)
    tags                    = optional(map(string), null)
  }))
  default = []

  validation {
    condition = (
      length(distinct([for access_point in var.access_points : access_point.name])) == length(var.access_points) &&
      alltrue([for access_point in var.access_points : trimspace(access_point.name) != ""]) &&
      alltrue([
        for access_point in var.access_points :
        contains(["directory", "general"], access_point.bucket_type) &&
        (access_point.policy == null ? true : can(jsondecode(access_point.policy)))
      ])
    )
    error_message = "access_points must use unique, non-empty names, select a general or directory bucket_type, and contain valid policy JSON when set."
  }
}

variable "analytics_configurations" {
  description = "S3 Analytics configurations for the general purpose bucket, keyed by a stable configuration name."
  type = map(object({
    filter = optional(object({
      prefix = optional(string)
      tags   = optional(map(string), {})
    }))
    storage_class_analysis = object({
      output_schema_version = optional(string, "V_1")
      destination = object({
        bucket_account_id = optional(string)
        bucket_arn        = string
        format            = optional(string, "CSV")
        prefix            = optional(string)
      })
    })
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, configuration in var.analytics_configurations :
      trimspace(name) != "" &&
      configuration.storage_class_analysis.output_schema_version == "V_1" &&
      configuration.storage_class_analysis.destination.format == "CSV" &&
      trimspace(configuration.storage_class_analysis.destination.bucket_arn) != ""
    ])
    error_message = "Analytics configuration names and destination bucket ARNs must be non-empty, output_schema_version must be V_1, and format must be CSV."
  }
}

variable "acl" {
  description = "Optional canned ACL to apply when enable_acl is true. Conflicts with access_control_policy."
  type        = string
  default     = null

  validation {
    condition = var.acl == null ? true : contains([
      "authenticated-read",
      "aws-exec-read",
      "bucket-owner-full-control",
      "bucket-owner-read",
      "log-delivery-write",
      "private",
      "public-read",
      "public-read-write",
    ], var.acl)
    error_message = "acl must be a supported Amazon S3 canned ACL."
  }
}

variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for the general purpose bucket."
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for the general purpose bucket."
  type        = bool
  default     = true
}

variable "blocked_encryption_types" {
  description = "Optional server-side encryption types to reject for object uploads. Set to [\"SSE-C\"] to block customer-provided encryption keys; null leaves the provider default."
  type        = set(string)
  default     = null

  validation {
    condition = var.blocked_encryption_types == null ? true : (
      length(var.blocked_encryption_types) <= 1 &&
      alltrue([for encryption_type in var.blocked_encryption_types : contains(["NONE", "SSE-C"], encryption_type)])
    )
    error_message = "blocked_encryption_types must be null or contain one of NONE or SSE-C."
  }
}

variable "bucket_name" {
  description = "Name of the general purpose S3 bucket. When null, Amazon S3 generates a name unless bucket_prefix is selected."
  type        = string
  default     = null

  validation {
    condition     = var.bucket_name == null ? true : trimspace(var.bucket_name) != ""
    error_message = "bucket_name must be null or a non-empty string."
  }
}

variable "bucket_namespace" {
  description = "Optional namespace for the general purpose bucket. Valid values are global and account-regional. Null uses the AWS global namespace default."
  type        = string
  default     = null

  validation {
    condition     = var.bucket_namespace == null ? true : contains(["account-regional", "global"], var.bucket_namespace)
    error_message = "bucket_namespace must be null, global, or account-regional."
  }
}

variable "bucket_policy" {
  description = "Optional S3 bucket policy JSON document used when configure_policy is true."
  type        = string
  default     = null

  validation {
    condition     = var.bucket_policy == null ? true : can(jsondecode(var.bucket_policy))
    error_message = "bucket_policy must be null or a valid JSON document."
  }
}

variable "bucket_prefix" {
  description = "Prefix from which Amazon S3 generates the general purpose bucket name when use_bucket_prefix is true."
  type        = string
  default     = null

  validation {
    condition     = var.bucket_prefix == null ? true : trimspace(var.bucket_prefix) != ""
    error_message = "bucket_prefix must be null or a non-empty string."
  }
}

variable "configure_policy" {
  description = "Whether to attach bucket_policy to the general purpose bucket."
  type        = bool
  default     = false
}

variable "cors_rules" {
  description = "Cross-Origin Resource Sharing rules for the general purpose bucket."
  type = list(object({
    allowed_methods = list(string)
    allowed_origins = list(string)
    allowed_headers = optional(list(string), [])
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number)
    id              = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.cors_rules :
      length(rule.allowed_methods) > 0 &&
      length(rule.allowed_origins) > 0 &&
      alltrue([for method in rule.allowed_methods : contains(["DELETE", "GET", "HEAD", "POST", "PUT"], method)]) &&
      try(rule.max_age_seconds >= 0, true)
    ])
    error_message = "Each CORS rule requires an origin, a supported uppercase HTTP method, and a non-negative max_age_seconds when set."
  }
}

variable "create_bucket" {
  description = "Whether to create a general purpose S3 bucket."
  type        = bool
  default     = true
}

variable "create_directory_bucket" {
  description = "Whether to create an S3 directory bucket in addition to any general purpose bucket."
  type        = bool
  default     = false
}

variable "data_redundancy" {
  description = "Data redundancy for the directory bucket."
  type        = string
  default     = "SingleAvailabilityZone"

  validation {
    condition     = contains(["SingleAvailabilityZone"], var.data_redundancy)
    error_message = "data_redundancy must be SingleAvailabilityZone."
  }
}

variable "directory_bucket_name" {
  description = "Name of the S3 directory bucket. The name must include the location-specific suffix required by Amazon S3."
  type        = string
  default     = null

  validation {
    condition     = var.directory_bucket_name == null ? true : trimspace(var.directory_bucket_name) != ""
    error_message = "directory_bucket_name must be null or a non-empty string."
  }
}

variable "enable_access_points" {
  description = "Whether to create the access points declared in access_points."
  type        = bool
  default     = false
}

variable "enable_acl" {
  description = "Whether to manage an ACL for the general purpose bucket. ACLs require an object ownership mode other than BucketOwnerEnforced."
  type        = bool
  default     = false
}

variable "enable_bucket_key" {
  description = "Whether to use an S3 Bucket Key for KMS-based server-side encryption."
  type        = bool
  default     = false
}

variable "enable_replication_configuration" {
  description = "Whether to configure replication for the general purpose bucket."
  type        = bool
  default     = false
}

variable "enable_s3_notification" {
  description = "Whether to manage EventBridge, Lambda, SNS, and SQS notifications for the general purpose bucket."
  type        = bool
  default     = false
}

variable "enable_website_configuration" {
  description = "Whether to configure static website hosting or redirection for the general purpose bucket."
  type        = bool
  default     = false
}

variable "error_document" {
  description = "Object key returned for website errors."
  type        = string
  default     = null

  validation {
    condition     = var.error_document == null ? true : trimspace(var.error_document) != ""
    error_message = "error_document must be null or a non-empty object key."
  }
}

variable "eventbridge" {
  description = "Whether to send bucket events to Amazon EventBridge when notifications are enabled."
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "Whether Terraform may delete bucket objects when destroying a bucket. Deleted objects are not recoverable, and Object Lock retention can still prevent deletion."
  type        = bool
  default     = false
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for the general purpose bucket."
  type        = bool
  default     = true
}

variable "index_document" {
  description = "Object suffix used as the website index document."
  type        = string
  default     = null

  validation {
    condition     = var.index_document == null ? true : trimspace(var.index_document) != ""
    error_message = "index_document must be null or a non-empty suffix."
  }
}

variable "intelligent_tiering_configurations" {
  description = "S3 Intelligent-Tiering configurations for the general purpose bucket, keyed by a stable configuration name."
  type = map(object({
    status = optional(string, "Enabled")
    filter = optional(object({
      prefix = optional(string)
      tags   = optional(map(string), {})
    }))
    tiering = list(object({
      access_tier = string
      days        = number
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, configuration in var.intelligent_tiering_configurations :
      trimspace(name) != "" &&
      contains(["Disabled", "Enabled"], configuration.status) &&
      length(configuration.tiering) > 0 &&
      length(distinct([for tier in configuration.tiering : tier.access_tier])) == length(configuration.tiering) &&
      alltrue([
        for tier in configuration.tiering :
        contains(["ARCHIVE_ACCESS", "DEEP_ARCHIVE_ACCESS"], tier.access_tier) &&
        tier.days <= 730 &&
        (tier.access_tier == "ARCHIVE_ACCESS" ? tier.days >= 90 : tier.days >= 180)
      ])
    ])
    error_message = "Intelligent-Tiering configurations require a non-empty name, Enabled or Disabled status, and unique tiers between 90-730 days for ARCHIVE_ACCESS or 180-730 days for DEEP_ARCHIVE_ACCESS."
  }
}

variable "inventory_configurations" {
  description = "S3 Inventory configurations for the general purpose bucket, keyed by a stable configuration name."
  type = map(object({
    enabled                  = optional(bool, true)
    included_object_versions = optional(string, "All")
    optional_fields          = optional(set(string), [])
    filter_prefix            = optional(string)
    schedule_frequency       = optional(string, "Daily")
    destination = object({
      account_id = optional(string)
      bucket_arn = string
      format     = optional(string, "CSV")
      prefix     = optional(string)
      encryption = optional(object({
        sse_kms = optional(object({
          key_id = string
        }))
        sse_s3 = optional(bool, false)
      }))
    })
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, configuration in var.inventory_configurations :
      trimspace(name) != "" &&
      contains(["All", "Current"], configuration.included_object_versions) &&
      contains(["Daily", "Weekly"], configuration.schedule_frequency) &&
      contains(["CSV", "ORC", "Parquet"], configuration.destination.format) &&
      trimspace(configuration.destination.bucket_arn) != "" &&
      (configuration.destination.encryption == null ? true :
        ((configuration.destination.encryption.sse_kms != null) != configuration.destination.encryption.sse_s3)
      )
    ])
    error_message = "Inventory configurations require valid versions, schedule, format, destination ARN, and exactly one of SSE-KMS or SSE-S3 when destination encryption is set."
  }
}

variable "kms_key_id" {
  description = "Optional KMS key ARN or ID used when sse_algorithm is aws:kms or aws:kms:dsse."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_id == null ? true : trimspace(var.kms_key_id) != ""
    error_message = "kms_key_id must be null or a non-empty KMS key ARN or ID."
  }
}

variable "lambda_notifications" {
  description = "Lambda function notification destinations. Callers must grant Amazon S3 permission to invoke each function."
  type = list(object({
    lambda_function_arn = string
    events              = list(string)
    filter_prefix       = optional(string)
    filter_suffix       = optional(string)
    id                  = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for notification in var.lambda_notifications :
      trimspace(notification.lambda_function_arn) != "" && length(notification.events) > 0
    ])
    error_message = "Each Lambda notification requires a non-empty function ARN and at least one S3 event."
  }
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for current and noncurrent objects in the general purpose bucket."
  type = list(object({
    id     = string
    status = string
    filter = optional(object({
      object_size_greater_than = optional(string)
      object_size_less_than    = optional(string)
      prefix                   = optional(string)
      tag = optional(object({
        key   = string
        value = string
      }))
      tags = optional(map(string))
    }))
    abort_incomplete_multipart_upload = optional(object({
      days_after_initiation = number
    }))
    expiration = optional(object({
      days                         = optional(number)
      date                         = optional(string)
      expired_object_delete_marker = optional(bool)
    }))
    transition = optional(list(object({
      days          = optional(number)
      date          = optional(string)
      storage_class = string
    })))
    noncurrent_version_expiration = optional(object({
      noncurrent_days           = number
      newer_noncurrent_versions = optional(number)
    }))
    noncurrent_version_transition = optional(list(object({
      noncurrent_days           = number
      storage_class             = string
      newer_noncurrent_versions = optional(number)
    })))
  }))
  default = []

  validation {
    condition = (
      length(distinct([for rule in var.lifecycle_rules : rule.id])) == length(var.lifecycle_rules) &&
      alltrue([
        for rule in var.lifecycle_rules :
        trimspace(rule.id) != "" &&
        contains(["Disabled", "Enabled"], rule.status) &&
        try(rule.abort_incomplete_multipart_upload.days_after_initiation > 0, true) &&
        (
          rule.abort_incomplete_multipart_upload != null ||
          rule.expiration != null ||
          length(coalesce(rule.transition, [])) > 0 ||
          rule.noncurrent_version_expiration != null ||
          length(coalesce(rule.noncurrent_version_transition, [])) > 0
        )
      ])
    )
    error_message = "Lifecycle rules require unique non-empty IDs, Enabled or Disabled status, at least one action, and positive multipart upload cleanup days."
  }

  validation {
    condition = alltrue([
      for rule in var.lifecycle_rules :
      (try(rule.filter.tag, null) == null || try(rule.filter.tags, null) == null) &&
      (
        rule.expiration == null ||
        (
          (try(rule.expiration.days, null) == null ? 0 : 1) +
          (try(rule.expiration.date, null) == null ? 0 : 1) +
          (try(rule.expiration.expired_object_delete_marker, null) == null ? 0 : 1) == 1 &&
          try(rule.expiration.days > 0, true)
        )
      )
    ])
    error_message = "Lifecycle filters cannot set both tag and tags, and expiration must set exactly one of positive days, date, or expired_object_delete_marker."
  }

  validation {
    condition = alltrue([
      for rule in var.lifecycle_rules :
      alltrue([
        for transition in coalesce(rule.transition, []) :
        (try(transition.days, null) == null) != (try(transition.date, null) == null) &&
        try(transition.days > 0, true) &&
        contains(["DEEP_ARCHIVE", "GLACIER", "GLACIER_IR", "INTELLIGENT_TIERING", "ONEZONE_IA", "STANDARD_IA"], transition.storage_class)
      ]) &&
      try(rule.noncurrent_version_expiration.noncurrent_days > 0, true) &&
      try(rule.noncurrent_version_expiration.newer_noncurrent_versions > 0, true) &&
      alltrue([
        for transition in coalesce(rule.noncurrent_version_transition, []) :
        transition.noncurrent_days > 0 &&
        try(transition.newer_noncurrent_versions > 0, true) &&
        contains(["DEEP_ARCHIVE", "GLACIER", "GLACIER_IR", "INTELLIGENT_TIERING", "ONEZONE_IA", "STANDARD_IA"], transition.storage_class)
      ])
    ])
    error_message = "Lifecycle transitions must set exactly one positive days value or date, and all current and noncurrent transitions must use a supported storage class and positive day/version values."
  }
}

variable "lifecycle_configuration_timeouts" {
  description = "Optional create and update timeouts for the S3 lifecycle configuration."
  type = object({
    create = optional(string)
    update = optional(string)
  })
  default = null
}

variable "lifecycle_transition_default_minimum_object_size" {
  description = "Optional default minimum object-size behavior for lifecycle transitions."
  type        = string
  default     = null

  validation {
    condition = var.lifecycle_transition_default_minimum_object_size == null ? true : contains([
      "all_storage_classes_128K",
      "varies_by_storage_class",
    ], var.lifecycle_transition_default_minimum_object_size)
    error_message = "lifecycle_transition_default_minimum_object_size must be null, all_storage_classes_128K, or varies_by_storage_class."
  }
}

variable "location_name" {
  description = "Availability Zone ID or Local Zone ID in which to create the directory bucket."
  type        = string
  default     = null

  validation {
    condition     = var.location_name == null ? true : trimspace(var.location_name) != ""
    error_message = "location_name must be null or a non-empty zone ID."
  }
}

variable "location_type" {
  description = "Location type for the directory bucket."
  type        = string
  default     = "AvailabilityZone"

  validation {
    condition     = contains(["AvailabilityZone", "LocalZone"], var.location_type)
    error_message = "location_type must be AvailabilityZone or LocalZone."
  }
}

variable "logging_bucket_name" {
  description = "Destination bucket name for S3 server access logs."
  type        = string
  default     = null

  validation {
    condition     = var.logging_bucket_name == null ? true : trimspace(var.logging_bucket_name) != ""
    error_message = "logging_bucket_name must be null or a non-empty bucket name."
  }
}

variable "logging_enabled" {
  description = "Whether to deliver server access logs for the general purpose bucket."
  type        = bool
  default     = false
}

variable "logging_target_object_key_format" {
  description = "Optional server access log object-key format. Set exactly one partitioned_prefix or simple_prefix option. Null uses the S3 default simple format."
  type = object({
    partitioned_prefix = optional(object({
      partition_date_source = optional(string, "EventTime")
    }))
    simple_prefix = optional(bool, false)
  })
  default = null

  validation {
    condition = var.logging_target_object_key_format == null ? true : (
      (var.logging_target_object_key_format.partitioned_prefix != null) != var.logging_target_object_key_format.simple_prefix &&
      try(contains(["DeliveryTime", "EventTime"], var.logging_target_object_key_format.partitioned_prefix.partition_date_source), true)
    )
    error_message = "logging_target_object_key_format must select exactly one partitioned_prefix or simple_prefix; partition_date_source must be DeliveryTime or EventTime."
  }
}

variable "logging_target_prefix" {
  description = "Optional prefix for server access log object keys. Null uses logs/<source-bucket-name>/."
  type        = string
  default     = null
}

variable "metadata_configuration" {
  description = "Optional S3 Metadata inventory and journal table configuration for the general purpose bucket."
  type = object({
    inventory_table_configuration = object({
      configuration_state = optional(string, "ENABLED")
      encryption_configuration = optional(object({
        sse_algorithm = string
        kms_key_arn   = optional(string)
      }))
    })
    journal_table_configuration = object({
      encryption_configuration = optional(object({
        sse_algorithm = string
        kms_key_arn   = optional(string)
      }))
      record_expiration = object({
        expiration = optional(string, "ENABLED")
        days       = optional(number)
      })
    })
    create_timeout = optional(string)
  })
  default = null

  validation {
    condition = var.metadata_configuration == null ? true : (
      contains(["DISABLED", "ENABLED"], var.metadata_configuration.inventory_table_configuration.configuration_state) &&
      contains(["DISABLED", "ENABLED"], var.metadata_configuration.journal_table_configuration.record_expiration.expiration) &&
      (
        var.metadata_configuration.journal_table_configuration.record_expiration.expiration == "ENABLED" ?
        try(
          var.metadata_configuration.journal_table_configuration.record_expiration.days >= 7 &&
          var.metadata_configuration.journal_table_configuration.record_expiration.days <= 2147483647,
          false
        ) :
        var.metadata_configuration.journal_table_configuration.record_expiration.days == null
      ) &&
      alltrue([
        for encryption in [
          var.metadata_configuration.inventory_table_configuration.encryption_configuration,
          var.metadata_configuration.journal_table_configuration.encryption_configuration,
        ] :
        contains(["AES256", "aws:kms"], encryption.sse_algorithm) &&
        (encryption.sse_algorithm == "aws:kms" ? try(trimspace(encryption.kms_key_arn) != "", false) : try(encryption.kms_key_arn, null) == null)
        if encryption != null
      ])
    )
    error_message = "metadata_configuration states must be ENABLED or DISABLED; enabled journal retention requires 7-2147483647 days while disabled retention must omit days; encryption must use AES256 without a KMS key or aws:kms with a KMS key ARN."
  }
}

variable "metric_configurations" {
  description = "S3 request metrics configurations for the general purpose bucket, keyed by a stable configuration name."
  type = map(object({
    filter = optional(object({
      access_point = optional(string)
      prefix       = optional(string)
      tags         = optional(map(string), {})
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for name, configuration in var.metric_configurations : trimspace(name) != ""])
    error_message = "Metric configuration names must be non-empty."
  }
}

variable "object_lock_enabled" {
  description = "Whether to enable S3 Object Lock on the general purpose bucket at creation time. object_lock_configuration also enables it automatically."
  type        = bool
  default     = false
}

variable "object_lock_configuration" {
  description = "Optional Object Lock default retention configuration for the general purpose bucket. Requires versioning to be Enabled."
  type = object({
    token = optional(string)
    default_retention = optional(object({
      mode  = optional(string, "GOVERNANCE")
      days  = optional(number)
      years = optional(number)
    }))
  })
  default = null

  validation {
    condition = var.object_lock_configuration == null ? true : (
      var.object_lock_configuration.default_retention == null ? true : (
        contains(["COMPLIANCE", "GOVERNANCE"], var.object_lock_configuration.default_retention.mode) &&
        (try(var.object_lock_configuration.default_retention.days, null) == null) != (try(var.object_lock_configuration.default_retention.years, null) == null) &&
        try(var.object_lock_configuration.default_retention.days > 0, true) &&
        try(var.object_lock_configuration.default_retention.years > 0, true)
      )
    )
    error_message = "Object Lock retention mode must be COMPLIANCE or GOVERNANCE and set exactly one positive days or years value."
  }
}

variable "object_ownership" {
  description = "Object ownership mode for the general purpose bucket. BucketOwnerEnforced disables ACLs."
  type        = string
  default     = "BucketOwnerEnforced"

  validation {
    condition     = contains(["BucketOwnerEnforced", "BucketOwnerPreferred", "ObjectWriter"], var.object_ownership)
    error_message = "object_ownership must be BucketOwnerEnforced, BucketOwnerPreferred, or ObjectWriter."
  }
}

variable "redirect_all_requests_to" {
  description = "Optional website redirect target. This conflicts with index, error, and routing rule configuration."
  type = object({
    host_name = string
    protocol  = optional(string)
  })
  default = null

  validation {
    condition = var.redirect_all_requests_to == null ? true : (
      trimspace(var.redirect_all_requests_to.host_name) != "" &&
      (try(var.redirect_all_requests_to.protocol, null) == null || contains(["http", "https"], var.redirect_all_requests_to.protocol))
    )
    error_message = "redirect_all_requests_to requires a host name and protocol, when set, must be http or https."
  }
}

variable "region" {
  description = "Optional AWS Region in which the module manages S3 resources. Defaults to the Region configured by the caller's AWS provider."
  type        = string
  default     = null

  validation {
    condition     = var.region == null ? true : trimspace(var.region) != ""
    error_message = "region must be null or a non-empty AWS Region name."
  }
}

variable "replication_configuration" {
  description = "Replication role and rules used when enable_replication_configuration is true."
  type = object({
    role  = string
    token = optional(string)
    rule = list(object({
      id       = string
      status   = string
      priority = optional(number)
      filter = optional(object({
        tag = optional(object({
          key   = string
          value = string
        }))
        tags   = optional(map(any))
        prefix = optional(string)
      }))
      delete_marker_replication = optional(object({
        status = string
      }))
      existing_object_replication = optional(object({
        status = string
      }))
      destination = object({
        access_control_translation = optional(object({
          owner = string
        }))
        account = optional(string)
        bucket  = string
        encryption_configuration = optional(object({
          replica_kms_key_id = string
        }))
        metrics = optional(object({
          status = string
          event_threshold = optional(object({
            minutes = number
          }))
        }))
        replication_time = optional(object({
          status = string
          time = object({
            minutes = number
          })
        }))
        storage_class = optional(string)
      })
      source_selection_criteria = optional(object({
        replica_modifications = optional(object({
          status = string
        }))
        sse_kms_encrypted_objects = optional(object({
          status = string
        }))
      }))
    }))
  })
  default = null

  validation {
    condition = var.replication_configuration == null ? true : (
      trimspace(var.replication_configuration.role) != "" &&
      length(var.replication_configuration.rule) > 0 &&
      length(distinct([for rule in var.replication_configuration.rule : rule.id])) == length(var.replication_configuration.rule) &&
      alltrue([
        for rule in var.replication_configuration.rule :
        trimspace(rule.id) != "" &&
        contains(["Disabled", "Enabled"], rule.status) &&
        trimspace(rule.destination.bucket) != "" &&
        try(contains(["Disabled", "Enabled"], rule.delete_marker_replication.status), true) &&
        try(contains(["Disabled", "Enabled"], rule.existing_object_replication.status), true) &&
        try(contains(["Disabled", "Enabled"], rule.destination.metrics.status), true) &&
        try(contains(["Disabled", "Enabled"], rule.destination.replication_time.status), true)
      ])
    )
    error_message = "replication_configuration requires a role, unique rule IDs, a destination bucket, and Enabled or Disabled statuses."
  }
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for the general purpose bucket."
  type        = bool
  default     = true
}

variable "routing_rule" {
  description = "Structured website routing rules. Use this or routing_rules, but not both."
  type = list(object({
    condition = object({
      http_error_code_returned_equals = optional(string)
      key_prefix_equals               = optional(string)
    })
    redirect = object({
      host_name               = optional(string)
      http_redirect_code      = optional(string)
      protocol                = optional(string)
      replace_key_prefix_with = optional(string)
      replace_key_with        = optional(string)
    })
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.routing_rule :
      (try(rule.redirect.protocol, null) == null || contains(["http", "https"], rule.redirect.protocol)) &&
      !(try(rule.redirect.replace_key_prefix_with, null) != null && try(rule.redirect.replace_key_with, null) != null)
    ])
    error_message = "Website routing rules may use http or https and cannot set both replace_key_prefix_with and replace_key_with."
  }
}

variable "routing_rules" {
  description = "JSON-encoded website routing rules. Use an empty string when unused. Conflicts with routing_rule."
  type        = string
  default     = ""

  validation {
    condition     = var.routing_rules == "" ? true : can(jsondecode(var.routing_rules))
    error_message = "routing_rules must be empty or contain valid JSON."
  }
}

variable "sns_notifications" {
  description = "SNS topic notification destinations. Callers must configure each topic policy to permit delivery from Amazon S3."
  type = list(object({
    topic_arn     = string
    events        = list(string)
    filter_prefix = optional(string)
    filter_suffix = optional(string)
    id            = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for notification in var.sns_notifications :
      trimspace(notification.topic_arn) != "" && length(notification.events) > 0
    ])
    error_message = "Each SNS notification requires a non-empty topic ARN and at least one S3 event."
  }
}

variable "sqs_notifications" {
  description = "SQS queue notification destinations. Callers must configure each queue policy to permit delivery from Amazon S3."
  type = list(object({
    queue_arn     = string
    events        = list(string)
    filter_prefix = optional(string)
    filter_suffix = optional(string)
    id            = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for notification in var.sqs_notifications :
      trimspace(notification.queue_arn) != "" && length(notification.events) > 0
    ])
    error_message = "Each SQS notification requires a non-empty queue ARN and at least one S3 event."
  }
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm for the general purpose bucket."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms", "aws:kms:dsse"], var.sse_algorithm)
    error_message = "sse_algorithm must be AES256, aws:kms, or aws:kms:dsse."
  }
}

variable "tags" {
  description = "Tags to apply to all module-created buckets and access points."
  type        = map(string)
  default     = {}
}

variable "use_bucket_prefix" {
  description = "Whether to generate the general purpose bucket name from bucket_prefix instead of using bucket_name."
  type        = bool
  default     = false
}

variable "versioning" {
  description = "Optional versioning status for the general purpose bucket: Enabled, Suspended, or Disabled. Null leaves versioning unmanaged."
  type        = string
  default     = null

  validation {
    condition     = var.versioning == null ? true : contains(["Disabled", "Enabled", "Suspended"], var.versioning)
    error_message = "versioning must be null, Disabled, Enabled, or Suspended."
  }
}
