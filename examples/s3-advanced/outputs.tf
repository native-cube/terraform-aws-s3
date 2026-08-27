output "bucket_arn" {
  description = "ARN of the advanced general purpose bucket."
  value       = module.s3_advanced.bucket_arn
}

output "bucket_domain_names" {
  description = "Global and regional domain names of the bucket."
  value = {
    global   = module.s3_advanced.bucket_domain_name
    regional = module.s3_advanced.bucket_regional_domain_name
  }
}

output "bucket_region" {
  description = "AWS Region reported by the bucket resource."
  value       = module.s3_advanced.bucket_region
}
