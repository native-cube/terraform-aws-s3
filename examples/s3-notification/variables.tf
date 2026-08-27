variable "region" {
  description = "AWS Region in which to create the bucket."
  type        = string
  default     = "eu-west-2"
}

variable "bucket_prefix" {
  description = "Globally unique bucket-name prefix."
  type        = string
  default     = "example-notifications-"
}

variable "lambda_function_arn" {
  description = "Existing Lambda function ARN. Its resource policy must allow invocation by Amazon S3."
  type        = string
}

variable "sns_topic_arn" {
  description = "Existing SNS topic ARN whose policy allows delivery from Amazon S3."
  type        = string
}

variable "sqs_queue_arn" {
  description = "Existing SQS queue ARN whose policy allows delivery from Amazon S3."
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
