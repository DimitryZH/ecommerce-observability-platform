terraform {
  backend "gcs" {
    bucket = "sre-platform-staging-507220-tf-state"
    prefix = "terraform/staging-runtime"
  }
}
