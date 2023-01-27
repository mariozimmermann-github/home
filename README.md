# Uniagro Selecionados

Local para controlar versão de códigos proprietários da Empresa.


# Protheus

## Novas políticas de Tecnologia da Informação

- Dev só terá acesso à ambiente de desenvolvimento.

- T-Cloud somente para Administradores internos.

- Usuários T-Cloud para 3º apenas por 4horas sob demanda no ambiente Dev.

- Credenciais FTP somente para Administradores internos.

- Ambiente DEV-Uniagro ninguém deve conectar, é para manobra interna do TI, não deve ser homologado processo de negócio nenum neste ambiente.


## Segue o passo para envio de nova versão de Fonte - Git flow da Uniagro

- Só mando pra branch main depois de homologado e testado pelo usuário requisitante
- Erro crítico em prod de fontes puxar fonte para branch hot-fix
- Manutenção e correção na branch bug-fix - precisa número de chamado no service desk TRS ou TI Uniagro
- Implementação de novo programa na branch feature


## Segue o passo a passo para redeploy de pacote:
  
- Promover o rpo de: prod para: DevUniagro  
- Excluir fonte  
- Compila o novo fonte  
- Promove o fonte para: Prod

