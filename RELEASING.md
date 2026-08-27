# Releasing

This repository uses semantic version tags. Terraform Registry accepts `x.y.z` and `vx.y.z`; this project uses the `v` prefix consistently.

## v1.0.0 checklist

1. Confirm the GitHub repository is public, is named `terraform-aws-s3`, and has a concise repository description.
2. Confirm the repository's license or internal usage terms are explicitly set according to the owner's policy.
3. Update `CHANGELOG.md` with the release date and final user-facing changes.
4. Run `make release-check` with Terraform, terraform-docs, TFLint, and Trivy installed.
5. Merge the release changes to `main` and confirm both GitHub Actions jobs pass.
6. Create and push the annotated tag:

   ```shell
   git tag -a v1.0.0 -m "terraform-aws-s3 v1.0.0"
   git push origin v1.0.0
   ```

7. Create GitHub release notes from `CHANGELOG.md` and verify the tag appears in the intended public or private Terraform Registry.

Do not reuse or move a published version tag. If the release needs correction after publication, make the fix and publish a new patch version.
