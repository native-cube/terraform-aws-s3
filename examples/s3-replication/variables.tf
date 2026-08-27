variable "region" {
  description = "AWS Region in which to create the source bucket."
  type        = string
  default     = "eu-west-2"
}

variable "bucket_prefix" {
  description = "Globally unique source bucket-name prefix."
  type        = string
  default     = "example-replication-source-"
}

variable "replication_role_arn" {
  description = "Existing IAM role ARN that Amazon S3 can assume for replication."
  type        = string
}

variable "destination_bucket_arn" {
  description = "ARN of an existing, versioned destination S3 bucket."
  type        = string
}

variable "tags" {
  description = "Tags applied to the source bucket."
  type        = map(string)
  default = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}
