# Terraform

Infraestrutura compartilhada do servidor aplicada ao k3s pelo GitHub Actions.

## Responsabilidade

Este diretório gerencia recursos de plataforma: namespaces compartilhados,
quotas, políticas e, futuramente, operadores, observabilidade e serviços usados
por mais de uma aplicação.

A plataforma de dados inclui uma instância MongoDB autenticada no namespace
`data`. Senhas são bootstrapadas diretamente como Kubernetes Secrets e nunca
declaradas no Terraform, pois o provider persistiria seus valores no state.

Deployment, Service, Ingress, database, user, volume e Secret exclusivos devem
ficar no repositório da própria aplicação.

## Estrutura

```text
terraform/
├── environments/
│   └── production.tfvars
├── examples/
│   └── application-infra/
├── backend.tf
├── locals.tf
├── main.tf
├── outputs.tf
├── providers.tf
├── variables.tf
└── versions.tf
```

## Backend

O state usa o backend Kubernetes:

```text
namespace: kube-system
secret:    tfstate-default-almeidas-server-infra
```

Isso já fornece locking. Como o state está no mesmo servidor, backups externos
do k3s são obrigatórios antes de considerar a infraestrutura recuperável. A
migração futura para um backend S3 compatível, como Backblaze B2, é recomendada.

## Execução local

```bash
cd terraform
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -var-file=environments/production.tfvars
```

O kubeconfig local precisa alcançar o cluster. Nunca faça commit dele.

## GitHub Actions

O Environment `production` precisa destes Secrets:

| Nome | Uso |
| --- | --- |
| `TS_OAUTH_CLIENT_ID` | OAuth Client do Tailscale |
| `TS_OAUTH_SECRET` | autenticação efêmera do runner |
| `KUBECONFIG_BASE64` | kubeconfig codificado em base64 |

E desta variável:

```text
KUBE_API_SERVER=https://almeidas-server-1.tail257531.ts.net:6443
TERRAFORM_APPLY_ENABLED=false
```

Pull requests executam `plan`. Somente push em `main` executa `apply`.
Mesmo em `main`, o apply permanece bloqueado enquanto
`TERRAFORM_APPLY_ENABLED` não for explicitamente alterado para `true`.

## Uso por outros projetos

O workflow `.github/workflows/terraform-kubernetes.yml` é reutilizável por
outros repositórios privados da conta. Um exemplo completo do caller está em
`examples/application-infra/workflow.yml.example`.

Cada projeto continua tendo:

- seu próprio diretório `terraform/`;
- backend com `secret_suffix` exclusivo;
- Environment `production`;
- state isolado;
- ownership apenas dos seus recursos.

Criar um repositório no GitHub não cria infraestrutura automaticamente. O
projeto passa a ter `plan/apply` automático quando adiciona o Terraform e o
caller do workflow reutilizável.

## Primeiro apply

O AddOn k3s `migrated-apps` ainda controla os aplicativos atuais. Não declare
nem importe esses recursos neste state. O primeiro plano deste diretório deve
mostrar apenas os recursos de plataforma explicitamente adicionados aqui.
