locals {
  mongodb_namespace = kubernetes_namespace_v1.managed["data"].metadata[0].name
  mongodb_labels = {
    "app.kubernetes.io/name"       = "mongodb"
    "app.kubernetes.io/instance"   = "platform"
    "app.kubernetes.io/component"  = "database"
    "app.kubernetes.io/managed-by" = "terraform"
  }
}

resource "kubernetes_persistent_volume_v1" "mongodb" {
  metadata {
    name = "platform-mongodb-data"
    labels = {
      "app.kubernetes.io/name"       = "mongodb"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    capacity = {
      storage = var.mongodb_storage_size
    }
    access_modes                     = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name               = "manual-local"
    volume_mode                      = "Filesystem"

    persistent_volume_source {
      local {
        path = var.mongodb_local_path
      }
    }

    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["almeidas-server"]
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "mongodb" {
  metadata {
    name      = "mongodb-data"
    namespace = local.mongodb_namespace
    labels    = local.mongodb_labels
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "manual-local"
    volume_name        = kubernetes_persistent_volume_v1.mongodb.metadata[0].name

    resources {
      requests = {
        storage = var.mongodb_storage_size
      }
    }
  }
}

resource "kubernetes_service_v1" "mongodb_headless" {
  metadata {
    name      = "mongodb"
    namespace = local.mongodb_namespace
    labels    = local.mongodb_labels
  }

  spec {
    cluster_ip = "None"
    selector   = local.mongodb_labels

    port {
      name        = "mongodb"
      port        = 27017
      target_port = "mongodb"
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_service_v1" "mongodb_access" {
  metadata {
    name      = "mongodb-access"
    namespace = local.mongodb_namespace
    labels    = local.mongodb_labels
  }

  spec {
    selector     = local.mongodb_labels
    external_ips = [var.tailscale_ipv4]

    port {
      name        = "mongodb"
      port        = 27018
      target_port = "mongodb"
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_stateful_set_v1" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = local.mongodb_namespace
    labels    = local.mongodb_labels
  }

  spec {
    service_name = kubernetes_service_v1.mongodb_headless.metadata[0].name
    replicas     = 1

    selector {
      match_labels = local.mongodb_labels
    }

    update_strategy {
      type = "RollingUpdate"
    }

    template {
      metadata {
        labels = local.mongodb_labels
      }

      spec {
        termination_grace_period_seconds = 60

        container {
          name              = "mongodb"
          image             = var.mongodb_image
          image_pull_policy = "IfNotPresent"

          env_from {
            secret_ref {
              name = "mongodb-admin"
            }
          }

          port {
            name           = "mongodb"
            container_port = 27017
            protocol       = "TCP"
          }

          readiness_probe {
            exec {
              command = [
                "sh",
                "-ec",
                "mongosh --quiet --username \"$MONGO_INITDB_ROOT_USERNAME\" --password \"$MONGO_INITDB_ROOT_PASSWORD\" --authenticationDatabase admin --eval \"quit(db.adminCommand('ping').ok ? 0 : 2)\"",
              ]
            }
            initial_delay_seconds = 15
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 6
          }

          liveness_probe {
            exec {
              command = [
                "sh",
                "-ec",
                "mongosh --quiet --username \"$MONGO_INITDB_ROOT_USERNAME\" --password \"$MONGO_INITDB_ROOT_PASSWORD\" --authenticationDatabase admin --eval \"quit(db.adminCommand('ping').ok ? 0 : 2)\"",
              ]
            }
            initial_delay_seconds = 60
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "2"
              memory = "2Gi"
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/data/db"
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.mongodb.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_resource_quota_v1.namespace,
    kubernetes_limit_range_v1.namespace,
  ]
}

