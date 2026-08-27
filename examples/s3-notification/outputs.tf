output "bucket_arn" {
  description = "ARN of the notification-enabled bucket."
  value       = module.s3_notification.bucket_arn
}
