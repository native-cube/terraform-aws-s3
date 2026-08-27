variable "region" {
  description = "AWS Region in which to create the bucket."
  type        = string
  default     = "eu-west-2"
}

variable "bucket_prefix" {
  description = "Globally unique website bucket-name prefix."
  type        = string
  default     = "example-website-"
}

variable "tags" {
  description = "Tags applied to the bucket."
  type        = map(string)
  default = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}
