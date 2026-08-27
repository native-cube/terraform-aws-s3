output "bucket_id" {
  description = "Generated website bucket name."
  value       = module.s3_website.bucket_id
}

output "website_endpoint" {
  description = "S3 website endpoint."
  value       = module.s3_website.website_endpoint
}
