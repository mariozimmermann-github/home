#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
/*
+-----------+-----------+-------+-----------------------------------------------------------------+------+----------+
| Funcao    | UNIA025   | Autor | Manoel M Mariante                                               | Data |dez/2021  |
|-----------+-----------+-------+-----------------------------------------------------------------+------+----------|
| Descricao | PE na rotina de Televendas, após a gravação ddo pedido de vendas                                      |
|           |  da comissão                                                                                          |
|           |                                                                                                       |
|-----------+-------------------------------------------------------------------------------------------------------|
| Sintaxe   | executado via PE TMKVFIM                                                                              |
+-----------+-------------------------------------------------------------------------------------------------------+
*/
User Function UNIA025(cNumSUA,cNumSC5)
	Local aAreaSC5:=SC5->(GetArea())
	Local aAreaSC6:=SC6->(GetArea())
   
	DbSelectArea('SC5')
	DbSetOrder(1)
	IF !dbSeek(xFilial('SC5')+cNumSC5)
       	RestArea(aAreaSC5)
		Return
	End

	RecLock('SC5', .f.)
	SC5->C5_SITWMS   :='00'
	MsUnlock()

	DbSelectArea('SC6')
	DbSetOrder(1)
	dbSeek(xFilial('SC6')+cNumSC5)
	While C6_FILIAL+C6_NUM == xFilial('SC6')+cNumSC5 .AND. !EOF()
		if SC6->C6_PRCVEN == SC6->C6_PRUNIT
            dbskip()
			Loop
		END

        nComis1  :=Posicione('SA3',1,xFilial('SA3')+SC5->C5_VEND1,'A3_COMIS')
        
        If nComis1==0
            nComis1  :=Posicione('DA0',1,xFilial('DA0')+SC5->C5_TABELA,'DA0_COMISS')
        end
		RecLock('SC6', .f.)
		SC6->C6_XDESC   :=(1-(SC6->C6_PRCVEN / SC6->C6_PRUNIT)) * 100
		SC6->C6_COMIS1  :=nComis1
        //ConOut('gravei '+CValToChar(nComis1))
		MsUnlock()

		dbskip()
	end

	RestArea(aAreaSC6)
	RestArea(aAreaSC5)

Return
