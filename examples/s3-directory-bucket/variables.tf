variable "region" {
  description = "AWS Region containing the selected directory bucket location."
  type        = string
  default     = "eu-west-2"
}

variable "directory_bucket_name" {
  description = "Globally unique directory bucket name including the required location suffix, for example example--euw2-az1--x-s3."
  type        = string
}

variable "location_name" {
  description = "Availability Zone ID or Local Zone ID for the directory bucket."
  type        = string
}

variable "location_type" {
  description = "Directory bucket location type."
  type        = string
  default     = "AvailabilityZone"
}

variable "tags" {
  description = "Tags applied to the directory bucket."
  type        = map(string)
  default = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}
