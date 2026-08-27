variable "region" {
  description = "AWS Region in which to create the bucket. S3 Metadata must be available in the selected Region."
  type        = string
  default     = "eu-west-2"
}

variable "bucket_prefix" {
  description = "Unique prefix from which Amazon S3 generates the bucket name."
  type        = string
  default     = "example-advanced-"
}

variable "bucket_namespace" {
  description = "S3 bucket namespace to use."
  type        = string
  default     = "global"
}

variable "logging_bucket_name" {
  description = "Name of an existing bucket configured to receive S3 server access logs."
  type        = string
}

variable "reporting_bucket_arn" {
  description = "ARN of an existing bucket whose policy permits S3 Inventory and Analytics exports."
  type        = string
}

variable "tags" {
  description = "Tags applied to the bucket."
  type        = map(string)
  default = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}
