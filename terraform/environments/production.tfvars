namespaces = {
  apps = {
    labels = {
      environment = "production"
    }
    quota = {
      requests_cpu    = "2"
      requests_memory = "4Gi"
      limits_cpu      = "4"
      limits_memory   = "8Gi"
      pods            = "30"
      services        = "20"
    }
    defaults = {
      request_cpu    = "100m"
      request_memory = "128Mi"
      limit_cpu      = "500m"
      limit_memory   = "512Mi"
    }
  }

  shared-services = {
    labels = {
      environment = "production"
    }
    quota = {
      requests_cpu    = "2"
      requests_memory = "4Gi"
      limits_cpu      = "4"
      limits_memory   = "8Gi"
      pods            = "20"
      services        = "20"
    }
    defaults = {
      request_cpu    = "100m"
      request_memory = "128Mi"
      limit_cpu      = "1"
      limit_memory   = "1Gi"
    }
  }
}
