resource "kubernetes_namespace_v1" "managed" {
  for_each = var.namespaces

  metadata {
    name   = each.key
    labels = merge(local.managed_by_labels, each.value.labels)
  }
}

resource "kubernetes_resource_quota_v1" "namespace" {
  for_each = local.namespaces_with_quota

  metadata {
    name      = "namespace-quota"
    namespace = kubernetes_namespace_v1.managed[each.key].metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = each.value.quota.requests_cpu
      "requests.memory" = each.value.quota.requests_memory
      "limits.cpu"      = each.value.quota.limits_cpu
      "limits.memory"   = each.value.quota.limits_memory
      "pods"            = each.value.quota.pods
      "services"        = each.value.quota.services
    }
  }
}

resource "kubernetes_limit_range_v1" "namespace" {
  for_each = local.namespaces_with_defaults

  metadata {
    name      = "container-defaults"
    namespace = kubernetes_namespace_v1.managed[each.key].metadata[0].name
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = each.value.defaults.limit_cpu
        memory = each.value.defaults.limit_memory
      }
      default_request = {
        cpu    = each.value.defaults.request_cpu
        memory = each.value.defaults.request_memory
      }
    }
  }
}
