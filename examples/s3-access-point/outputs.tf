output "bucket_arn" {
  description = "ARN of the bucket exposed through the VPC access point."
  value       = module.s3_access_point.bucket_arn
}
