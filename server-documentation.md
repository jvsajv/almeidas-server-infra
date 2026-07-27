# Inventário atual do servidor

Levantamento somente leitura feito em 27/07/2026.

## Host

- Ubuntu 26.04 LTS, 4 CPUs e 7,1 GiB de RAM;
- volume raiz de 98 GiB, com 35 GiB usados;
- k3s `v1.36.2+k3s1`, nó único `almeidas-server`;
- Docker e containerd do k3s rodam separadamente;
- Tailscale `100.109.102.107`;
- Netdata ativo;
- Headlamp e Netdata são as ferramentas atuais de monitoramento;
- `cloudflare-traefik-bridge.service` encaminha
  `127.0.0.1:80` para o NodePort `127.0.0.1:30080`.

## Plataforma k3s

- Traefik 3.7.4, instalado pelo HelmChart embarcado no k3s;
- CoreDNS, metrics-server e local-path-provisioner padrão;
- Headlamp no namespace `kube-system`;
- API Kubernetes em `*:6443`;
- Service do Traefik como LoadBalancer, ainda com external IP `pending`;
- Ingress público chega ao Traefik pelo bridge local/Cloudflare;
- Funnel do Tailscale está habilitado.

Os componentes padrão do k3s devem continuar sob responsabilidade do próprio
k3s. Eles não devem ser duplicados no Terraform.

## Plataforma de dados

Em 27/07/2026 foi iniciada a migração do MongoDB 4.4 sem autenticação para uma
instância MongoDB 7.0 autenticada no namespace `data`.

- o banco antigo permanece intacto durante a migração;
- backup lógico validado por checksum em
  `/home/jvsajv/backups/mongodb/`;
- 13 coleções e 575 documentos no momento do backup;
- Secret administrativo criado diretamente no Kubernetes, fora do Terraform
  state;
- volume novo com política `Retain`;
- endpoint interno planejado:
  `mongodb.data.svc.cluster.local:27017`;
- endpoint privado planejado:
  `100.109.102.107:27018`.

O endpoint privado deve ser alcançável somente pela tailnet. O encaminhamento
manual e não autenticado da porta `27017` será removido após o cutover.

MongoDB 8.0 ou superior não pode ser usado enquanto o projeto upstream mantiver
a incompatibilidade SERVER-121912 com kernels Linux 6.19+. O host usa kernel
7.0. MongoDB 7.0.39 foi escolhido como versão temporária suportada.

## Aplicações

### liga-cogumelo

- Deployment `liga-cogumelo`, uma réplica;
- imagem `taca-cogumelo-web-app:latest`;
- Service ClusterIP;
- Ingress Tailscale em `/liga-cogumelo`;
- Secret `liga-cogumelo-env`;
- PV/PVC local de 10 GiB, política `Retain`.

Ainda há uma instância Docker do mesmo projeto publicada na porta `8989`. Antes
de removê-la, confirme tráfego, dados e rollback; ela pode ser uma implantação
antiga coexistindo com a versão do k3s.

### role-iniciativa

- API e frontend em Deployments separados;
- imagens da aplicação identificadas por SHA do commit;
- MongoDB 4.4.18 em StatefulSet;
- PV/PVC do MongoDB de 20 GiB, política `Retain`;
- PV/PVC de uploads de 20 GiB, política `Retain`;
- Ingress para `roleiniciativa.com.br` e `www.roleiniciativa.com.br`;
- Secret `role-iniciativa-api-env`.

O MongoDB é específico dessa aplicação e deve ser gerenciado no repo
`role-iniciativa`, junto com backup, restore e política de upgrade. A versão 4.4
merece um plano separado de atualização; não deve ser trocada durante a migração
para Terraform.

## Fonte de verdade atual

Os namespaces, workloads, Services, Ingresses e volumes das aplicações possuem
metadados do AddOn k3s `migrated-apps`, cuja origem é:

```text
/var/lib/rancher/k3s/server/manifests/migrated-apps.yaml
```

Esse arquivo é reconciliado automaticamente pelo k3s. Editar os objetos
diretamente ou tentar gerenciá-los simultaneamente com Terraform causará drift.

Migração segura por aplicação:

1. copiar a definição efetiva para o repo da aplicação, sem copiar valores de
   Secrets;
2. declarar os recursos equivalentes em Terraform;
3. inicializar um state exclusivo da aplicação;
4. remover apenas a seção dessa aplicação do `migrated-apps.yaml`;
5. importar os recursos existentes no state, sem executar apply destrutivo;
6. exigir um plano vazio antes do primeiro apply;
7. migrar os Secrets para SOPS ou External Secrets;
8. testar backup e restore dos volumes antes de qualquer mudança.

## Acesso da pipeline

O kubeconfig original aponta para `https://127.0.0.1:6443`. O certificado da API
foi atualizado em 27/07/2026 para também conter:

```yaml
tls-san:
  - almeidas-server-1.tail257531.ts.net
  - 100.109.102.107
```

A configuração está em `/etc/rancher/k3s/config.yaml`. Após o restart, foram
validados:

- certificado TLS com os dois SANs;
- nó `almeidas-server` em estado `Ready`;
- todos os Deployments disponíveis;
- StatefulSet `mongo-db` em `1/1`;
- todos os PVs e PVCs em estado `Bound`;
- API acessível pelo MagicDNS da tailnet;
- rotas de `liga-cogumelo` e `role-iniciativa` retornando HTTP 200.

O Environment `production` do GitHub deve usar:

```text
KUBE_API_SERVER=https://almeidas-server-1.tail257531.ts.net:6443
```

## Alocação de responsabilidade proposta

| Recurso | Responsável |
| --- | --- |
| Instalação/configuração do k3s no host | automação de bootstrap do servidor |
| Traefik, CoreDNS, metrics-server | k3s |
| Headlamp, observabilidade, operadores | este repo central |
| Redis/Postgres compartilhado | este repo central |
| Deployments, Services e Ingresses | repo de cada aplicação |
| Mongo/database/user exclusivos | repo de cada aplicação |
| PV/PVC e backup exclusivos | repo de cada aplicação |
