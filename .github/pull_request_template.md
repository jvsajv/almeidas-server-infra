## O que muda

Descreva os recursos e o motivo da alteração.

## Ownership

- [ ] O recurso pertence à infraestrutura compartilhada.
- [ ] Não existe outro reconciliador controlando o mesmo objeto.

## Segurança e persistência

- [ ] O diff não contém credenciais, kubeconfig ou state.
- [ ] Mudanças em dados têm backup e procedimento de restore.
- [ ] Novas portas, rotas e permissões foram documentadas.

## Validação

- [ ] `terraform fmt -check -recursive`
- [ ] `terraform validate`
- [ ] Plano revisado integralmente
- [ ] Rollback definido

