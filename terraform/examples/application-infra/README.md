# Infraestrutura de uma aplicação

Este diretório é apenas uma referência. Copie os arquivos para o repositório da
aplicação; não aplique esta configuração a partir do repo central.

O repo da aplicação deve ser dono de:

- Deployment, Service e Ingress da aplicação;
- Secrets específicos do serviço (preferencialmente via External Secrets/SOPS);
- database, role e grants exclusivos;
- filas, buckets ou caches que só existam por causa da aplicação.

O repo central continua dono de serviços compartilhados, operadores, storage
classes, namespaces, observabilidade e políticas do cluster.
