#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "RWMAKE.CH"
/*
Valida % Shelf Life dos lotes x Pedidos
Mario Zimmermann
29/05/2023
*/
User Function MTSLDLOT()
	Local lRet      := .T.
	Local aArea  	:= GetArea()
	Local _cProd    := PARAMIXB[1]
	Local _cLocal   := PARAMIXB[2]
	Local _cLote    := PARAMIXB[3]

	Private _CRLF           :=CHR(13)+chr(10)
    /*
    lUtiliza:= ExecBlock("MTSLDLOT",.F.,.F.,{	(cAliasSBF)->BF_PRODUTO	,;
                                                (cAliasSBF)->BF_LOCAL	,;
                                                (cAliasSBF)->BF_LOTECTL	,;
                                                (cAliasSBF)->BF_NUMLOTE	,;
                                                (cAliasSBF)->BF_LOCALIZ	,;
                                                (cAliasSBF)->BF_NUMSERI	,;
                                                nEmpenho				,;
                                                .F.						})
    */                                                                            
	If Left(AllTrim(FunName()),6) $ "MATA41/MATA44/MATA45/MATA46" .And. SC5->(FieldPos("C5_ULOTE"))>0
		_cULOTE := Posicione("SC5",1,xFilial("SC5")+SC6->C6_NUM,"SC5->C5_ULOTE") //1=Minimo 70%;2=Ate 100%;3=Independente da validade
		If _cULOTE $ "12"

			cQuery := " SELECT MAX(B8_DTVALID) AS B8_DTVALID, MIN(B8_DFABRIC) AS B8_DFABRIC, MIN(B8_DATA) AS B8_DATA FROM " + RetSqlTab("SB8") +_CRLF
			cQuery += " WHERE " + RetSqlDel("SB8") +_CRLF
			cQuery += " AND " + RetSqlFil("SB8") +_CRLF
			cQuery += " AND B8_PRODUTO  = '" + _cProd   + "' "+_CRLF
			cQuery += " AND B8_LOCAL    = '" + _cLocal  + "' "+_CRLF
			cQuery += " AND B8_LOTECTL  = '" + _cLote   + "' "+_CRLF

			dbUseArea( .T.,"TOPCONN", TCGENQRY(,,cQuery),"_TRX", .F., .T.)

			IF !_TRX->(EOF()) .And. !Empty(_TRX->B8_DTVALID) .And. !Empty(Iif(!Empty(_TRX->B8_DFABRIC),_TRX->B8_DFABRIC,_TRX->B8_DATA))
				_nDiasTot := sTod(_TRX->B8_DTVALID) - sTod(iif(!Empty(_TRX->B8_DFABRIC),_TRX->B8_DFABRIC,_TRX->B8_DATA))
				_nDiasRes := sTod(_TRX->B8_DTVALID) - dDataBase
				_nPerVal := (_nDiasRes/_nDiasTot)*100
				If _cULOTE == "1" .And. _nPerVal <= 70
					lRet:= .F.
				ElseIf _cULOTE == "2" .And. _nPerVal <= 100
					lRet:= .F.
				EndIf
			EndIf

			DbSelectArea('_TRX')
			_TRX->(DBCLOSEAREA())
			RestArea(aArea)
		EndIf
	EndIf
	RestArea(aArea)
Return lRet
