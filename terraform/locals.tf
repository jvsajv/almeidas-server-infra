locals {
  managed_by_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "infra.almeidas.dev/scope"     = "platform"
  }

  namespaces_with_quota = {
    for name, config in var.namespaces : name => config
    if config.quota != null
  }

  namespaces_with_defaults = {
    for name, config in var.namespaces : name => config
    if config.defaults != null
  }
}
