variable "region" {
  description = "AWS Region in which to create the bucket and access point."
  type        = string
  default     = "eu-west-2"
}

variable "bucket_prefix" {
  description = "Globally unique bucket-name prefix."
  type        = string
  default     = "example-access-point-"
}

variable "access_point_name" {
  description = "Name of the S3 access point."
  type        = string
  default     = "application"
}

variable "vpc_id" {
  description = "Existing VPC to which the access point is restricted."
  type        = string
}

variable "tags" {
  description = "Tags applied to the bucket and access point."
  type        = map(string)
  default = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}
