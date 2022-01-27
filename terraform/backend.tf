terraform {
backend "gcs" {
  bucket = "ipla-1652-tfstate-bucket"   # GCS bucket name to store terraform tfstate
  prefix = "ipla-1652-first-app"           # Update to desired prefix name. Prefix name should be unique for each Terraform project having same remote state bucket.
  }
}