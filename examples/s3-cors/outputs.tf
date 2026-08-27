output "bucket_id" {
  description = "Generated name of the CORS-enabled bucket."
  value       = module.s3_cors.bucket_id
}
