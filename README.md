# Uniagro Selecionados

Local para controlar versão de códigos proprietários da Empresa.


# Protheus

## Novas políticas de Tecnologia da Informação

- Dev só terá acesso à ambiente de desenvolvimento.

- T-Cloud somente para Administradores internos.

- Ambiente DEV-Uniagro ninguém deve conectar, é para manobra interna do TI, não deve ser homologado processo de negócio nenum neste ambiente.


## Segue o passo para envio de nova versão de Fonte - Git flow da Uniagro

- Faz o commit em 

- só mando pra branch main depois de homologado e testado
- Erro crítico em prod de fontes puxar fonte para branch hot-fix
- Manutenção e correção na branch bug-fix
- Implementação de novo programa na branch feature


## Segue o passo a passo para redeploy de pacote:
  
- Promover o rpo de: prod para: DevUniagro  
- Excluir fonte  
- Compila o novo fonte  
- Promove o fonte para: Prod

