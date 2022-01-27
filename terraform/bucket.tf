# Specify the GCP provider
provider "google" {
project = var.project_id
region  = var.region
}

provider "google-beta" {
  region      = var.region
  project     = var.project_id
}

# ------------------------------------------------------------------------------
# CREATE A STORAGE BUCKET
# - force_destroy: allows terraform to destroy when there are files on the bucket
# ------------------------------------------------------------------------------

resource "google_storage_bucket" "cdn_bucket" {
  name          = var.bucket_name
  storage_class = "MULTI_REGIONAL"
  location      = var.region
  project       = var.project_id
  force_destroy = true
}

# ------------------------------------------------------------------------------
# CREATE A BACKEND CDN BUCKET
# ------------------------------------------------------------------------------
 
resource "google_compute_backend_bucket" "cdn_backend_bucket" {
  name        = var.bucket_name_backend
  description = "Backend bucket for serving static content through CDN"
  bucket_name = google_storage_bucket.cdn_bucket.name
  enable_cdn  = true
  project     = var.project_id
}

# ------------------------------------------------------------------------------
# CREATE A GLOBAL PUBLIC IP ADDRESS
# ------------------------------------------------------------------------------
 
resource "google_compute_global_address" "cdn_public_address" {
  name         = "cdn-public-address"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
  project      = var.project_id
}


# ------------------------------------------------------------------------------
# CREATE A URL MAP (web-map => cdn-url-map)
# ------------------------------------------------------------------------------
 
resource "google_compute_url_map" "cdn_url_map" {
  name            = "cdn-url-map"
  description     = "CDN URL map to cdn_backend_bucket"
  default_service = google_compute_backend_bucket.cdn_backend_bucket.self_link
  project         = var.project_id
}
 
# ------------------------------------------------------------------------------
# CREATE HTTP PROXY
# ------------------------------------------------------------------------------
 
resource "google_compute_target_http_proxy" "cdn_http_proxy" {
  name             = "cdn-http-proxy"
  url_map          = google_compute_url_map.cdn_url_map.self_link
  project          = var.project_id
}


## ------------------------------------------------------------------------------
## CREATE A GOOGLE COMPUTE MANAGED CERTIFICATE
## ------------------------------------------------------------------------------
#resource "google_compute_managed_ssl_certificate" "cdn_certificate" {
#  provider = google-beta
#  project  = var.project_id
# 
#  name = "cdn-managed-certificate"
# 
#  managed {
#    domains = [local.cdn_domain]
#  }
#}
# 
## ------------------------------------------------------------------------------
## CREATE HTTPS PROXY
## ------------------------------------------------------------------------------
# 
#resource "google_compute_target_https_proxy" "cdn_https_proxy" {
#  name             = "cdn-https-proxy"
#  url_map          = google_compute_url_map.cdn_url_map.self_link
#  ssl_certificates = [google_compute_managed_ssl_certificate.cdn_certificate.self_link]
#  project          = var.project_id
#}

# ------------------------------------------------------------------------------
# CREATE A GLOBAL FORWARDING RULE
# ------------------------------------------------------------------------------
 
resource "google_compute_global_forwarding_rule" "cdn_global_forwarding_rule" {
  name       = "cdn-global-forwarding-http-rule"
  target     = google_compute_target_http_proxy.cdn_http_proxy.self_link
  ip_address = google_compute_global_address.cdn_public_address.address
  port_range = "80"
  project    = var.project_id
}

## ------------------------------------------------------------------------------
## CREATE DNS RECORD
## ------------------------------------------------------------------------------
# 
#resource "google_dns_record_set" "cdn_dns_a_record" {
#  managed_zone = var.managed_zone # Name of your managed DNS zone
#  name         = "${local.cdn_domain}."
#  type         = "A"
#  ttl          = 3600 # 1 hour
#  rrdatas      = [google_compute_global_address.cdn_public_address.address]
#  project      = var.project
#}

# ------------------------------------------------------------------------------
# MAKE THE BUCKET PUBLIC
# ------------------------------------------------------------------------------
 
resource "google_storage_bucket_iam_member" "all_users_viewers" {
  bucket = google_storage_bucket.cdn_bucket.name
  role   = "roles/storage.legacyObjectReader"
  member = "allUsers"
}

# ------------------------------------------------------------------------------
# CREATE TRIGGER to deploy files to branch every new commit on master
# ------------------------------------------------------------------------------
resource "google_cloudbuild_trigger" "create_deploy_trigger" {
  name    = "build-and-deploy-terraform-app"
  github {
    owner = var.repo_owner
    name  = var.repo_name
    push {
      branch = "master"
    }
  }
  substitutions = {
    _ANGULAR_APP_BUCKET_PATH = format("gs://%s", var.bucket_name)
  }

  filename   = "terraform/cloudbuild.yaml"
  provider   = google-beta
}

# ------------------------------------------------------------------------------
# UPLOAD FILES TO BUCKET
# ------------------------------------------------------------------------------
provider "null" {
  version = "~> 2.1"
}

resource "null_resource" "upload_folder_content" {
  depends_on = [google_storage_bucket.cdn_bucket]
  # Copy files
  provisioner "local-exec" {
    command = "gsutil cp -r ${var.local_file_path}/* gs://${var.bucket_name}/"
  }
  # Set web configuration
  provisioner "local-exec" {
    command = "gsutil web set -m index.html gs://${var.bucket_name}"
  }
  # Set public permission to view files on the bucket
  provisioner "local-exec" {
    command = "gsutil acl ch -u AllUsers:R -r gs://${var.bucket_name}"
  }
}

