namespaces = {
  data = {
    labels = {
      environment = "production"
      purpose     = "stateful-services"
    }
    quota = {
      requests_cpu    = "2"
      requests_memory = "4Gi"
      limits_cpu      = "4"
      limits_memory   = "6Gi"
      pods            = "10"
      services        = "20"
    }
    defaults = {
      request_cpu    = "250m"
      request_memory = "512Mi"
      limit_cpu      = "2"
      limit_memory   = "2Gi"
    }
  }
}
