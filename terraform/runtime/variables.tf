variable "project_id" {
  description = "Existing staging project that hosts the runtime layer."
  type        = string
  default     = "sre-platform-staging-507220"
}

variable "region" {
  description = "Region containing the approved zonal runtime cluster."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Single zone for the minimal Standard GKE cluster."
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "Existing network name. This configuration never creates a network."
  type        = string
  default     = "default"
}

variable "subnetwork_name" {
  description = "Existing subnetwork name. This configuration never creates a subnetwork."
  type        = string
  default     = "default"
}

variable "node_machine_type" {
  description = "Fixed machine type for the single idle staging node."
  type        = string
  default     = "e2-medium"

  validation {
    condition     = var.node_machine_type == "e2-medium"
    error_message = "The cost-bounded runtime baseline permits only one e2-medium node."
  }
}

variable "runtime_labels" {
  description = "Labels applied to the staging runtime cluster and its node."
  type        = map(string)
  default = {
    "cost-profile" = "demo"
    environment    = "staging"
    platform       = "sre-platform"
    scope          = "runtime"
  }
}
