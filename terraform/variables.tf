variable "project_id" {
description = "Google Project ID."
type        = string
}

variable "bucket_name" {
description = "GCS Bucket name. Value should be unique ."
type        = string
}

variable "bucket_name_backend" {
description = "GCS Bucket name. Value should be unique ."
type        = string
}

variable "region" {
description = "Google Cloud region"
type        = string
default     = "EU"
}

variable "repo_name" {
  description = "GitHub Repository name"
  type        = string
}

variable "repo_owner" {
  description = "User owning the GitHub Repository"
  type        = string
}

variable "local_file_path" {
  description = "Location of the local application is build"
  type = string
}
