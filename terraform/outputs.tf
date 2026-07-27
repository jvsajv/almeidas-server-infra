output "managed_namespaces" {
  description = "Namespaces disponíveis para os repositórios de aplicações."
  value       = sort(keys(kubernetes_namespace_v1.managed))
}
