# Instruções para agentes

Este arquivo define as regras obrigatórias para qualquer agente de IA ou pessoa
que altere este repositório.

## Objetivo

Manter a infraestrutura compartilhada do servidor `almeidas-server` de forma
declarativa, revisável, recuperável e sem misturar o ciclo de vida da plataforma
com o das aplicações.

Leia também:

- `server-documentation.md`;
- `terraform/README.md`;
- `.github/workflows/terraform.yml`.

## Ambiente real

- host: Ubuntu 26.04 LTS;
- cluster: k3s de nó único;
- acesso privado: Tailscale;
- ingresso: Traefik, bridge local e Cloudflare;
- produção: qualquer `terraform apply` afeta serviços reais.

Nunca presuma que este é um ambiente descartável.

## Limites de responsabilidade

Pertence a este repositório:

- configuração compartilhada da plataforma;
- namespaces e políticas centrais;
- operadores do cluster;
- observabilidade;
- serviços usados por várias aplicações;
- documentação e automação de recuperação.

Pertence ao repositório de cada aplicação:

- Deployment, Service e Ingress;
- database, user e grants exclusivos;
- PV/PVC, cache, fila ou bucket exclusivos;
- configuração e Secrets da aplicação.

Se remover uma aplicação também deveria remover o recurso, o recurso não
pertence a este repositório.

## Segurança

- Nunca leia, registre ou faça commit de valores de Kubernetes Secrets.
- Nunca faça commit de kubeconfig, tokens, senhas, chaves ou arquivos `.tfstate`.
- Marcar uma variável como `sensitive` não impede que seu valor chegue ao state.
- Prefira SOPS ou External Secrets para credenciais de aplicações.
- Não exponha novas portas publicamente sem documentar origem, destino e motivo.
- Restrinja o GitHub Actions à API `6443` pela tailnet.

## Terraform

- Execute Terraform somente dentro de `terraform/`.
- Use versões de providers limitadas e mantenha `.terraform.lock.hcl`.
- Execute `terraform fmt -check -recursive` e `terraform validate`.
- Analise o plano inteiro antes de aplicar.
- Pull requests fazem `plan`; apenas `main` pode fazer `apply`.
- Não use `-target` como fluxo normal.
- Não use provisioners `local-exec` ou `remote-exec` para contornar providers.
- Não altere state manualmente sem backup e plano de recuperação.
- Cada aplicação deve ter state separado.

## Recursos existentes

O AddOn `migrated-apps`, vindo de
`/var/lib/rancher/k3s/server/manifests/migrated-apps.yaml`, ainda reconcilia os
aplicativos atuais.

Nunca declare o mesmo objeto simultaneamente no manifest e no Terraform.
Para migrar:

1. reproduza a configuração no repo correto;
2. preserve nomes, selectors, volumes e políticas de retenção;
3. remova somente a aplicação em migração do manifest;
4. importe os objetos no state correto;
5. exija um plano sem mudanças destrutivas;
6. valide aplicação, ingress e persistência.

Não recrie PVs nem StatefulSets como forma de importação.

## Operações no servidor

- Prefira inspeções somente leitura.
- Antes de reiniciar k3s, valide a configuração e registre o motivo.
- Depois de uma mudança, confirme nó `Ready`, Deployments disponíveis,
  StatefulSets prontos, PVCs `Bound` e rotas HTTP saudáveis.
- Faça backup antes de mudanças em storage, banco, certificados ou state.
- Não remova o container Docker antigo de `liga-cogumelo` sem confirmar tráfego,
  dados e rollback.

## Convenções

- Nomes Kubernetes em kebab-case.
- Labels recomendadas de `app.kubernetes.io/*`.
- Recursos devem declarar requests e limits.
- Volumes de dados devem ter estratégia documentada de backup e restore.
- Imagens de aplicação devem usar tag imutável; não introduza `latest`.
- Explique decisões não óbvias em comentários curtos ou documentação.
- Atualize `server-documentation.md` quando a topologia real mudar.

## Critério de conclusão

Uma alteração de infraestrutura só está concluída quando:

- formatação e validação passam;
- o plano foi revisado;
- não há credenciais no diff;
- ownership e rollback estão claros;
- documentação foi atualizada;
- verificações de saúde proporcionais ao risco foram executadas.

