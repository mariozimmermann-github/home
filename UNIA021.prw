#include "totvs.ch"
#include "topconn.ch"
#include "rwmake.ch"
/*
/*
+-----------+-----------+-------+-------------------------------------+------+----------+
| Funcao    | UNIA021   | Autor | Manoel M Mariante                   | Data |11/2021   |
|-----------+-----------+-------+-------------------------------------+------+----------|
| Descricao | altera status do pedido para ser enviado para o WMS                       |
|           |                                                                           |
|           |                                                                           |
|-----------+---------------------------------------------------------------------------|
| Sintaxe   | executado via menu                                                        |
+-----------+---------------------------------------------------------------------------+
*/
User Function UNIA021()
	Local aArea := Getarea()
	IF Empty(SC5->C5_LIBEROK)
		MsgInfo('Pedido Não foi Liberado Comercialmente', 'Liberação Comercial Não Realizada')
		return
	end
	if SC5->C5_SITWMS<>'00' .AND.SC5->C5_SITWMS<>'  '
		MsgInfo('Pedido encontra-se na situação '+SC5->C5_SITWMS+'-'+U_FSitWMS(SC5->C5_SITWMS)+'.', 'Já enviado')
	ELSE

		If !MsgBox('Enviar Pedido para WMS?','Enviar para situação 05 ?','YESNO')
			return .t.
		End

		dbSelectArea("SC5")
		recLock("SC5",.f.)
		SC5->C5_SITWMS:='05'
		msUnlock()

		Restarea(aArea)
	END

Return NIL
