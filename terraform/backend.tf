terraform {
  # O namespace kube-system já existe antes do primeiro apply.
  # O backend usa Secret para o state e Lease para locking.
  backend "kubernetes" {
    namespace     = "kube-system"
    secret_suffix = "almeidas-server-infra"
  }
}
