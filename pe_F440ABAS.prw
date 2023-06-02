#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
/*
+-----------+-----------+-------+------------------------------------------------------+------+----------+
| Funcao    | F440ABA   | Autor | Manoel M Mariante                                    | Data |dez/2021  |
|-----------+-----------+-------+------------------------------------------------------+------+----------|
| Descricao | PE na rotina de Calculo de Comissoes nas rotinas de baixas manuais e tbem                  |
|           | por recalculo                                                                              |
|           |                                                                                            |
|-----------+--------------------------------------------------------------------------------------------|
| Sintaxe   | executado nas rotinas que geram a SE3 pela baixa do titulo                                 |
+-----------+--------------------------------------------------------------------------------------------+
*/
User Function F440ABAS()
	Local abases	:=PARAMIXB

	//ajusta comissao conforme o incentivo informado no produto
	if ExistBlock('UNIA022')
		abases:=u_unia022(abases)
	End
	

Return abases
