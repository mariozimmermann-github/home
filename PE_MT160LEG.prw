/*
|============================================================================|
|============================================================================|
|||-----------+---------+-------+------------------------+------+----------|||
||| Funcao    | MT160LEG| Autor | Denis Rodrigues        | Data |17/04/2019|||
|||-----------+---------+-------+------------------------+------+----------|||
||| Descricao |Ponto de Entrada: Manipula regras de cores na mBrowse  	   |||
|||-----------+------------------------------------------------------------|||
||| Sintaxe   | U_MT160LEG()                                               |||
|||-----------+------------------------------------------------------------|||
||| Parametros| ParamIxb  - Array contendo as regras para a apresentacao   |||
|||           |              das cores do status da Cotacao na mbrowse     |||
|||-----------+------------------------------------------------------------|||
||| Retorno   | aNewCores - Array contendo as regras para a apresentacao   |||
|||           |             das cores do status da Cotacao na mbrowse ja   |||
|||           |             manipulados pelo ponto de entrada              |||
|||-----------+------------------------------------------------------------|||
|||  Uso      | Especifico Totvs RS                                        |||
|||-----------+------------------------------------------------------------|||
|||                           ULTIMAS ALTERACOES                           |||
|||-------------+--------+-------------------------------------------------|||
||| Programador | Data   | Motivo da Alteracao                             |||
|||-------------+--------+-------------------------------------------------|||
|||             |        |                                                 |||
|||-------------+--------+-------------------------------------------------|||
|============================================================================|
|============================================================================|*/
User Function MT160LEG()

	Local aOldCores := aClone( ParamIxb[1] )
	Local aNewCores	:= {}
	Local nInd		:= 0

	aAdd(aLegenda, {'BR_LARANJA' ,'Portal'})
	aAdd(aLegenda, {'BR_CINZA'	 ,'Rejeitada - Fornecedor'})
	aAdd(aLegenda, {'BR_AZUL'    ,'Cotação Precificada'})

	aAdd(aNewCores, { "C8_PRECO > 0 "									   				, 'BR_AZUL'   }) //-- Cotação Precificada
	aAdd(aNewCores, { "Empty(C8_NUMPED) .And. C8_ACPORT = 'S' .And. C8_REJEITA <> 'S'"	, 'BR_LARANJA' })//-- Portal
	aAdd(aNewCores, { "Empty(C8_NUMPED) .And. C8_ACPORT = 'S' .And. C8_REJEITA =  'N'"	, 'BR_CINZA' })	 //Rejeitada - Fornecedor

	//| Cores Padrao do Sistema |
	For nInd := 1 To Len(aOldCores)
		aAdd(aNewCores, aOldCores[nInd] )
	Next nInd

Return( aNewCores )
