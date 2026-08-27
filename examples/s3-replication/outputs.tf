output "source_bucket_arn" {
  description = "ARN of the replication source bucket."
  value       = module.s3_replication.bucket_arn
}
