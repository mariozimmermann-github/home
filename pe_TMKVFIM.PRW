#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
/*
+-----------+-----------+-------+-----------------------------------------------------------------------+------+----------+
| Funcao    | TMKVFIM   | Autor | Manoel M Mariante                                                     | Data |dez/2021  |
|-----------+-----------+-------+-----------------------------------------------------------------------+------+----------|
| Descricao | PE após a gravação do pedido de vendas - https://tdn.totvs.com/pages/releaseview.action?pageId=6787791      |
|           |                                                                                                             |
|           |                                                                                                             |
|-----------+-------------------------------------------------------------------------------------------------------------|
| Sintaxe   | executado mo TMKA271                                                                                        |
+-----------+-------------------------------------------------------------------------------------------------------------+
*/
User Function TMKVFIM(cNumSUA,cNumSC5)
	//grava dados de comissao e percentual de desconto em campo informativo
	if ExistBlock('UNIA025')
		u_unia025(cNumSUA,cNumSC5)
	End
	

Return 
