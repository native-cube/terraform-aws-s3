# Codex Instructions

These instructions apply to the whole Terraform Amazon S3 module.

## Module Scope

- Keep this as a reusable S3 module, not a complete environment stack.
- Do not create KMS keys, IAM roles, Lambda functions, SNS topics, SQS queues, VPCs, or AWS provider configuration in the root module. Examples may configure providers and compose supporting resources.
- Support general purpose buckets, directory buckets, access points, and the provider-backed bucket configurations exposed by the public interface.

## Terraform Style

- Run `terraform fmt -recursive` after editing Terraform files.
- Keep root module files split by concern: `versions.tf`, `variables.tf`, `locals.tf`, `bucket.tf`, `security.tf`, `data_management.tf`, `integrations.tf`, `website.tf`, `access_points.tf`, and `outputs.tf`.
- Document every variable and output. Validate constrained values and use resource preconditions for cross-variable rules.
- Prefer `for_each` with stable keys for repeatable resources and `count` for optional singletons.
- Use `local.common_tags` for module-created resources and merge resource-specific tags on top.
- Never configure an AWS provider in the root module or hard-code Regions, accounts, credentials, ARNs, bucket names, VPCs, or KMS keys.

## S3 Practices

- Keep server-side encryption and all four public-access-block settings enabled by default.
- Do not enable ACLs by default. ACLs are incompatible with `BucketOwnerEnforced` ownership and must be explicitly configured.
- Replication requires source bucket versioning and a caller-supplied IAM role; this module does not create the role or destination bucket.
- Notification destinations and their resource policies or Lambda permissions are managed by callers.
- Directory bucket names and locations must be supplied by callers because they are Availability Zone or Local Zone specific.
- Do not enable `force_destroy` in production examples; deleted bucket objects are not recoverable.

## Examples And Documentation

- Keep examples under `examples/`, consuming the root module from `../..`.
- Update the README for user-facing behavior. Do not manually edit content between terraform-docs markers.
- Run `make docs` after changes affecting inputs, outputs, resources, or requirements.
- Do not commit state, credentials, generated plans, real `terraform.tfvars`, or `.terraform/` directories.

## Verification

Run `make check`, or run formatting, docs, initialization, validation, tests, and validation of every example separately. CI also runs TFLint, Trivy, and minimum/latest compatibility jobs. Never run `terraform apply` or `terraform destroy` unless explicitly requested and the target environment is confirmed.
