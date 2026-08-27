output "directory_bucket_arn" {
  description = "ARN of the directory bucket."
  value       = module.s3_directory_bucket.directory_bucket_arn
}

output "directory_bucket_name" {
  description = "Name of the directory bucket."
  value       = module.s3_directory_bucket.directory_bucket_name
}
