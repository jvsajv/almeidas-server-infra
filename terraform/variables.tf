variable "kubeconfig_path" {
  description = "Caminho do kubeconfig usado para acessar o k3s."
  type        = string
  default     = "~/.kube/config"
}

variable "namespaces" {
  description = "Namespaces gerenciados pela infraestrutura central."
  type = map(object({
    labels = optional(map(string), {})
    quota = optional(object({
      requests_cpu    = string
      requests_memory = string
      limits_cpu      = string
      limits_memory   = string
      pods            = string
      services        = string
    }))
    defaults = optional(object({
      request_cpu    = string
      request_memory = string
      limit_cpu      = string
      limit_memory   = string
    }))
  }))

  validation {
    condition     = alltrue([for name in keys(var.namespaces) : can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", name))])
    error_message = "Os nomes dos namespaces devem ser DNS labels válidos do Kubernetes."
  }
}

variable "mongodb_image" {
  description = "Imagem imutável da instância MongoDB compartilhada."
  type        = string
  default     = "docker.io/library/mongo:8.0.26-noble"
}

variable "mongodb_storage_size" {
  description = "Capacidade declarada do volume local do MongoDB."
  type        = string
  default     = "10Gi"
}

variable "mongodb_local_path" {
  description = "Diretório persistente no nó k3s."
  type        = string
  default     = "/home/jvsajv/data/mongodb"
}

variable "tailscale_ipv4" {
  description = "IP Tailscale do nó usado para acesso privado ao banco."
  type        = string
  default     = "100.109.102.107"
}
