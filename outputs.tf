output "bucket_arn" {
  description = "Amazon Resource Name (ARN) of the created general purpose S3 bucket, or null when creation is disabled."
  value       = try(aws_s3_bucket.main[0].arn, null)
}

output "bucket_id" {
  description = "ID and name of the created general purpose S3 bucket, or null when creation is disabled."
  value       = try(aws_s3_bucket.main[0].id, null)
}

output "bucket_domain_name" {
  description = "Bucket domain name of the created general purpose S3 bucket, or null when creation is disabled."
  value       = try(aws_s3_bucket.main[0].bucket_domain_name, null)
}

output "bucket_hosted_zone_id" {
  description = "Route 53 hosted zone ID of the created general purpose S3 bucket, or null when creation is disabled."
  value       = try(aws_s3_bucket.main[0].hosted_zone_id, null)
}

output "bucket_region" {
  description = "AWS Region of the created general purpose S3 bucket, or null when creation is disabled."
  value       = try(aws_s3_bucket.main[0].region, null)
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the created general purpose S3 bucket, or null when creation is disabled."
  value       = try(aws_s3_bucket.main[0].bucket_regional_domain_name, null)
}

output "directory_bucket_arn" {
  description = "Amazon Resource Name (ARN) of the created S3 directory bucket, or null when creation is disabled."
  value       = try(aws_s3_directory_bucket.main[0].arn, null)
}

output "directory_bucket_name" {
  description = "Name of the created S3 directory bucket, or null when creation is disabled."
  value       = try(aws_s3_directory_bucket.main[0].bucket, null)
}

output "access_points" {
  description = "Details for access points created by the module, keyed by access point name."
  value = {
    for name, access_point in aws_s3_access_point.main : name => {
      alias          = access_point.alias
      arn            = access_point.arn
      domain_name    = access_point.domain_name
      endpoints      = access_point.endpoints
      id             = access_point.id
      name           = access_point.name
      network_origin = access_point.network_origin
    }
  }
}

output "website_domain" {
  description = "Domain of the configured S3 bucket website, or null when website configuration is disabled."
  value       = try(aws_s3_bucket_website_configuration.main[0].website_domain, null)
}

output "website_endpoint" {
  description = "Endpoint of the configured S3 bucket website, or null when website configuration is disabled."
  value       = try(aws_s3_bucket_website_configuration.main[0].website_endpoint, null)
}
