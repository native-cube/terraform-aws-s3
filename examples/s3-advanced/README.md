# Advanced S3 data-management example

Creates a versioned general purpose bucket that demonstrates Object Lock default retention, SSE-C blocking, tagged lifecycle filters, incomplete multipart cleanup, partitioned access logs, Intelligent-Tiering, Inventory, Analytics, request metrics, bucket ABAC, and S3 Metadata tables.

Supply existing logging and reporting buckets with policies that permit S3 delivery. Object Lock is enabled when the bucket is created and should be treated as an irreversible bucket-level decision. S3 Metadata availability and account prerequisites vary by Region; confirm them before applying this example.
