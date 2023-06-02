#INCLUDE "TOTVS.CH"
#INCLUDE "RWMAKE.CH"
/*
+-----------+-------------+-------+-------------------------------------+------+----------+
| Funcao    |PE01NFESEFAZ | Autor | Manoel M Mariante                   | Data |dez/2021  |
|-----------+-------------+-------+-------------------------------------+------+----------|
| Descricao | PE na geração do XML do SEFAZ                                               |
|           | especifico UNIAGRO                                                          |
|           |                                                                             |
|-----------+-----------------------------------------------------------------------------|
| Sintaxe   | ponto de entrada no nfesefaz                                                |
|-----------+-----------------------------------------------------------------------------|
| Alterações| 22/dez - inclui o envio do email para operadores logistico                  |
|           | dd/mmm - xxxxx                                                              |
|           |                                                                             |
+-----------+-----------------------------------------------------------------------------+
*/
User Function PE01NFESEFAZ()

	Local aArea         := GetArea()
	Local aAreaSF2      := SF2->(GetArea())
	Local aAreaSD2      := SD2->(GetArea())
	Local aAreaSF1      := SF1->(GetArea())
	Local aAreaSD1      := SD1->(GetArea())
	Local aAreaSF4      := SF4->(GetArea())
	Local aAreaSB8      := SB8->(GetArea())
	Local cTipo         := ""
	Local aProduto      := PARAMIXB[1]
	Local cMensCli      := PARAMIXB[2]
	Local aDest		    := PARAMIXB[4]
	local cLog			:=''

	//aParam := {aProd,cMensCli,cMensFis,aDest,aNota,aInfoItem,aDupl,aTransp,aEntrega,aRetirada,aVeiculo,aReboque,aNfVincRur,aEspVol,aNfVinc,aDetPag,aObsCont,aProcRef}

	//Uso o CFOP para identificar o tipo da nota fiscal (entrada ou saida)
	If aProduto[1,7] >= '5000'
		cTipo := '1'//saida
	Else
		cTipo := '0'//entrada
	EndIf

	If cTipo = '1'
		//envio da DANFE e XML para o operador logistico, controlado pelo parâmetro abaixo. Caso esteja preenchido enviará também para ele
		// Manoel,22/12
		cMailWMS:=alltrim(SuperGetMV('ES_MAILWMS',.F.,''))
		cLog+='entre nas saidas '+cMailWMS+chr(13)+chr(10)
		If !empty(cMailWMS)
			cLog+='cMailWMS :'+cMailWMS+chr(13)+chr(10)
			aDest[16]:=alltrim(aDest[16])+";"+cMailWMS
		end

		// Mensagens observações
		dbSelectArea("SD2")
        dbSetOrder(3)       
        If dbSeek( xFilial('SD2') + SF2->F2_DOC + SF2->F2_SERIE )

			cMensCli += " Pedido de venda: " + SD2->D2_PEDIDO
		
		EndIf

		//MENSAGENS TES        

		cMensCli += SF4->F4_FORMULA

	Else   // entrada


	end

// atualiza dados para o NFESEFAZ
	PARAMIXB[2]   := cMensCli
	PARAMIXB[4]   := aDest
	//cLog+='PARAMIXB[4] : '+PARAMIXB[4] +chr(13)+chr(10)
	//memowrit('c:\temp\danfe'+alltrim(sf2->f2_doc)+'_'+strtran(time(),':',''),clog)

	RestArea(aAreaSF2)
	RestArea(aAreaSD2)
	RestArea(aAreaSF1)
	RestArea(aAreaSD1)
	RestArea(aAreaSF4)
	RestArea(aAreaSB8)
	RestArea(aArea)

Return(PARAMIXB) 
