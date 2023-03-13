# Uniagro Selecionados

Local para controlar versão de códigos proprietários da Empresa.

Ir Para:

[Repositório](https://github.com/uniagro-ind/home)
[Página](https://uniagro-ind.github.io/home/)


# Protheus

## Novas políticas de Tecnologia da Informação

- Dev só terá acesso à ambiente de desenvolvimento.

- T-Cloud somente para Administradores internos.

- Usuários T-Cloud para 3º apenas por 4horas sob demanda no ambiente Dev.

- Credenciais FTP somente para Administradores internos.

- Ambiente "devuniagro" ninguém deve conectar, é para manobra interna do TI, não deve ser homologado processo de negócio nenum neste ambiente.


## Segue o passo para envio de nova versão de Fonte - Git flow da Uniagro

-Para que seja aceita a alteração e colocada em produção é preciso enviar o número do chamado junto ao service desk do TI Uniagro no commit.

- Só mando pra branch main depois de homologado e testado pelo usuário requisitante
- Todos que quiserem desenvolver os fontes da uniagro devem partir de um código que venha do main, fazendo um clone e mudando para a branch conforme abaixo.
- Ao fazerem clone mudar a branch para o que forem fazer, ex:

     **feature** - Novo recurso na customização

     **hot-fix** - Corrigir erro critico em produção

     **bug-fix** - sera implantado na próxima release

- Após concluirem o trabalho devem fazer um pull request
- Validarei com o usuário requisitante se esta ok
- Farei um merge para branch main e deploy em produção.

## Segue o passo a passo para redeploy de pacote:
  
- Promover o rpo de: prod para: DevUniagro  
- Excluir fonte  
- Compila o novo fonte  
- Promove o fonte para: Prod



