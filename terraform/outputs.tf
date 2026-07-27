output "managed_namespaces" {
  description = "Namespaces disponíveis para os repositórios de aplicações."
  value       = sort(keys(kubernetes_namespace_v1.managed))
}

output "mongodb_internal_endpoint" {
  description = "Endpoint usado por aplicações dentro do cluster."
  value       = "mongodb.data.svc.cluster.local:27017"
}

output "mongodb_tailnet_endpoint" {
  description = "Endpoint privado para IDEs e ferramentas na tailnet."
  value       = "${var.tailscale_ipv4}:27018"
}
