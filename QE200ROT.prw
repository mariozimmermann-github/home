
#INCLUDE "RWMAKE.CH"

//* ----------------------------------------------------------- *
//* Programa..: QE200ROT.PRW                                    *
//* Autor.....:  		                                        *
//* Data......: 			                                    *
//* Nota......: Ponto de Entrada do Inspecao de Entradas        *
//* ----------------------------------------------------------- *

User Function QE200ROT()
	Local aRotina  := {}
	aAdd(aRotina, { "Adic. Nova Inpeção"  ,'U_QE200NEW()'    ,0,3}    )

Return(aRotina)

User Function QE200NEW()
	Local _lRet     := .T.
	Local _ni       := 0
	If MsgBox("Confirma a inclusao de uma nova inspecao para o lote "+QEK->QEK_LOTE,"ATENCAO","YESNO")
		DbSelectArea("QEK")
		_aItens  := {}
		_ni      := 1
		For _ni  := 1 to FCount()
			_cCpo := "QEK->"+Fieldname (_ni)
			_xVar := &_cCpo
			aadd(_aItens,{_ni,_xVar})
		Next
        _cProxIt    := "0000"
		_cQuery := " SELECT ISNULL(MAX(QEK_ITEMNF),'0000') AS ULTIMO FROM "+RetSqlName("QEK")
		_cQuery += " WHERE QEK_FILIAL   = '"+xFilial("QEK")+"' "
		_cQuery += " AND QEK_PRODUT     = '"+QEK->QEK_PRODUT+"' "
		_cQuery += " AND QEK_LOTE       = '"+QEK->QEK_LOTE+"' " '
		DbUseArea(.t., 'TOPCONN', TcGenQry (,, _cQuery), '_QtEnt', .f., .t.)
		_QtEnt->(DbGoTop())
		If !_QtEnt->(EOF())
			_cProxIt := _QtEnt->ULTIMO  
		EndIf
		_QtEnt->(DbCloseArea())
		DbSelectArea("QEK")
        _cProxIt    := Soma1(_cProxIt)
		RecLock("QEK",.T.)
		For _ni  := 1 to Len(_aItens)
			FieldPut (_aItens[_ni,1], _aItens[_ni,2])
		Next
		QEK->QEK_ITEMNF		:= _cProxIt
		QEK->QEK_LOCORI     := ""
		QEK->QEK_LOTORI     := ""
		QEK->QEK_NUMSEQ     := ""
		QEK->QEK_TES        := ""
		QEK->QEK_CERFOR     := ""
		QEK->QEK_CERQUA     := ""
		QEK->QEK_MOVEST     := ""
		QEK->QEK_ORIGEM     := "QIEA200"
		QEK->QEK_SITENT     := "1"
		QEK->QEK_SOLIC      := "QUALIDADE"
		DbSelectArea("QEK")
		QEK->(MsUnlock())
	EndIf
Return(_lRet)
