/*
|============================================================================|
|============================================================================|
|||-----------+---------+-------+------------------------+------+----------|||
||| Funcao    | MT150LEG| Autor | Denis Rodrigues        | Data |17/04/2019|||
|||-----------+---------+-------+------------------------+------+----------|||
||| Descricao |PE: Adiciona legendas e regras de cores no mBrowse MATA150  |||
|||           |Rotina de atualizacao manual das cotacoes de compra         |||
|||           |http://tdn.totvs.com.br/display/public/mp/MT150LEG+-+       |||
|||           |Adiciona+legendas+e+regras+de+cores+na+Mbrowse              |||
|||-----------+------------------------------------------------------------|||
||| Sintaxe   | U_MT150LEG()                                               |||
|||-----------+------------------------------------------------------------|||
||| Parametros|                                                            |||
|||-----------+------------------------------------------------------------|||
||| Retorno   | aRet      - Array                                          |||
|||           |           1 - Com novas regras de Cores na mBrowse         |||
|||           |           2 - Com novas cores para a legenda               |||
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
User Function MT150LEG()

	Local aArea := GetArea()
	Local nNum  := ParamIxb[1]
	Local aRet  := {}

	If nNum == 1

		aAdd( aRet, { " C8_PRECO > 0 "											   			, 'BR_AZUL'    })	//-- Cotação Precificada
		aAdd( aRet, { " Empty(C8_NUMPED) .And. C8_ACPORT == 'S' .And. C8_REJEITA <> 'S' "	, 'BR_LARANJA' })	//-- Disponivel Portal
		aAdd( aRet, { " Empty(C8_NUMPED) .And. C8_ACPORT == 'S' .And. C8_REJEITA == 'S' "	, 'BR_CINZA'   })	//-- Rejeitada - Fornecedor


	ElseIf nNum == 2

		aAdd( aRet, {'BR_LARANJA', 'Disponivel Portal' })
		aAdd( aRet, {'BR_CINZA'  , 'Rejeitada - Fornecedor' })
		aAdd( aRet, {'BR_AZUL'   , 'Cotação Precificada' })

	EndIf

	RestArea(aArea)

Return( aRet )
