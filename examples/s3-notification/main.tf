terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.61.0, < 7.0.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "s3_notification" {
  source = "../.."

  bucket_prefix     = var.bucket_prefix
  use_bucket_prefix = true

  enable_s3_notification = true
  eventbridge            = true

  lambda_notifications = [{
    id                  = "process-uploads"
    lambda_function_arn = var.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "incoming/"
  }]

  sns_notifications = [{
    id        = "object-removals"
    topic_arn = var.sns_topic_arn
    events    = ["s3:ObjectRemoved:*"]
  }]

  sqs_notifications = [{
    id            = "archive-events"
    queue_arn     = var.sqs_queue_arn
    events        = ["s3:ObjectCreated:CompleteMultipartUpload"]
    filter_prefix = "archive/"
  }]

  tags = var.tags
}
