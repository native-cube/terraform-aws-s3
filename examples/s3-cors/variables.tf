variable "region" {
  description = "AWS Region in which to create the bucket."
  type        = string
  default     = "eu-west-2"
}

variable "bucket_prefix" {
  description = "Globally unique bucket-name prefix."
  type        = string
  default     = "example-cors-"
}

variable "allowed_origins" {
  description = "Browser origins allowed by the CORS rule."
  type        = list(string)
  default     = ["https://www.example.com"]
}

variable "tags" {
  description = "Tags applied to the bucket."
  type        = map(string)
  default = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}
