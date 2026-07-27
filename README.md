# almeidas-server-infra

Repositório responsável pela infraestrutura base do meu servidor Linux e do
cluster k3s.

- [`server-documentation.md`](server-documentation.md) — inventário do host,
  rede, workloads e decisões de responsabilidade;
- [`repository-infrastructure-audit.md`](repository-infrastructure-audit.md) —
  classificação das configurações encontradas nos repos;
- [`AGENTS.md`](AGENTS.md) — convenções obrigatórias para agentes e pessoas que
  alterarem a infraestrutura;
- [`terraform/`](terraform/) — código Terraform, ambientes, exemplos e
  instruções de bootstrap.

Leia `AGENTS.md` antes de adicionar ou modificar qualquer recurso.
