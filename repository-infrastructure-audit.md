# Auditoria de infraestrutura nos repositórios

Levantamento realizado em 27/07/2026 na conta `jvsajv` e no servidor
`almeidas-server`.

## Regra de ownership

Um arquivo de infraestrutura não deve ser movido ao repo central apenas porque
usa Docker, Kubernetes ou GitHub Actions.

- Plataforma compartilhada ou configuração do host: `almeidas-server-infra`.
- Recurso que nasce e morre com uma aplicação: repo da aplicação.
- Build e publicação da imagem: repo da aplicação.
- Configuração padrão distribuída pelo k3s: continua sob responsabilidade do
  k3s.

## Resultado

| Repositório | Configuração encontrada | Destino |
| --- | --- | --- |
| `role-iniciativa-api` | Dockerfile, Compose e deploy k3s | permanece no repo; ganhará Terraform próprio |
| `role-iniciativa-front` | Dockerfile, Compose e deploy k3s | permanece no repo; ganhará Terraform próprio |
| `taca-cogumelo-web` | Dockerfile, Compose e deploy SSH/Docker | permanece no repo; será consolidado no k3s |
| `almeidas-server-checkup` | Compose, workflow e units systemd | projeto descontinuado e arquivado |
| `unknow-friends` | Deployment e Service em `kubernetes.yaml` | permanece no repo; não está no cluster atual |
| `kachow-elojob` | Compose e deploy multi-servidor | permanece no repo; não está no servidor atual |
| `multiverso-among` | arquivos locais não versionados | decidir se o serviço ainda deve existir |

Nenhum outro repositório consultado contém arquivos Terraform.

## Recursos que devem ser centralizados

Estes recursos existem no host ou cluster, mas ainda não possuem uma fonte de
verdade adequada:

- `/etc/rancher/k3s/config.yaml`, incluindo SANs da tailnet;
- `cloudflare-traefik-bridge.service`;
- namespaces, quotas e políticas compartilhadas;
- Headlamp;
- estratégia de backup do state e dos dados;
- observabilidade compartilhada e alertas;
- configuração de acesso do GitHub Actions pela tailnet.

Configurações padrão de Traefik, CoreDNS, metrics-server e
local-path-provisioner continuam sendo gerenciadas pelo k3s e não devem ser
duplicadas no Terraform.

## Problemas encontrados

### Reconciliadores concorrentes

O AddOn k3s `migrated-apps` ainda controla os objetos das aplicações. Os
workflows de Role Iniciativa executam `kubectl set image` e terminam com
sucesso, mas o AddOn posteriormente restaura as imagens `latest`.

### Liga Cogumelo duplicado

Há uma instância Docker publicada na porta `8989` e outra no k3s. A Action do
repo atualiza apenas a instância Docker. É necessário identificar a instância
canônica e confirmar a localização do banco SQLite antes de desativar uma delas.

### Server Checkup removido

O projeto não era mais usado e duplicava funções do Netdata e Headlamp. Em
27/07/2026 foram removidos do servidor:

- `server-monitor-agent.service`;
- checkout, banco SQLite e ambiente virtual;
- imagens Docker `deploy-web:latest` e `deploy-backend:latest`.

O repositório `jvsajv/almeidas-server-checkup` foi arquivado no GitHub. Após a
remoção, RAM e swap diminuíram e os componentes de monitoramento restantes
continuaram saudáveis.

### Arquivos locais sensíveis

O checkout do servidor de `role-iniciativa-api` contém backups de `.env` e
artefatos não versionados. Eles não devem ser copiados, adicionados ao Git ou
usados como fonte de verdade durante a migração.

## Ordem de migração

1. Copiar e auditar `migrated-apps.yaml`, sem valores de Secrets.
2. Declarar e importar namespaces/políticas no repo central.
3. Declarar e importar API, MongoDB e volumes no repo da API.
4. Declarar e importar frontend e Ingress no repo do frontend.
5. Declarar e importar Liga Cogumelo no repo da aplicação.
6. Desabilitar o AddOn antigo somente depois de todos os planos serem vazios.
7. Testar rotas, persistência e rollback.
8. Consolidar a instância Docker duplicada.
9. Manter o Server Checkup arquivado; Netdata e Headlamp são as ferramentas
   atuais de monitoramento.

## Condição para remover configuração antiga

Um manifest ou workflow antigo só pode ser removido quando:

- os recursos correspondentes estiverem importados no state correto;
- o plano não propuser recriações;
- PVs/PVCs mantiverem nome, caminho e política `Retain`;
- Secrets existentes não forem incluídos no state;
- aplicação, banco e Ingress tiverem sido testados;
- houver procedimento de rollback.
