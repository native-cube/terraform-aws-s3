output "bucket_arn" {
  description = "ARN of the general purpose bucket."
  value       = module.s3_bucket.bucket_arn
}

output "bucket_id" {
  description = "Generated name of the general purpose bucket."
  value       = module.s3_bucket.bucket_id
}
