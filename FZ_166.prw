#INCLUDE "PROTHEUS.CH"
#INCLUDE "APVT100.CH"

Static __nSem := 0
Static __PulaItem := .F.
Static __aOldTela :={}

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o	 ³ FZ_166    ³ Autor ³ Desenv.    ACD      ³ Data ³ 17/06/01  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Movimentacao interna de produtos                           ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametro ³ ExpC1 = Caso queira padronizar programas de movimentacao in³±±
±±³          ³         terna deve passar o nome do programa               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso	     ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function FZ_166()
	Local aTela
	Local nOpc
	//IF !Type("lVT100B") == "L"
	//	Private lVT100B := .F.
	//EndIf

	//If ACDGet170()
	//	Return ACDV166X(0)
	//EndIf
	aTela := VtSave()
	ACDV166X(1)
	VTCLear()
	VtRestore(,,,,aTela)
Return 1

Static Function ACDV166X(nOpc)
	Local cAliasCB8	:= " "
	Local cKey04  := VTDescKey(04)
	Local cKey09  := VTDescKey(09)
	Local cKey12  := VTDescKey(12)
	Local cKey16  := VTDescKey(16)
	Local cKey22  := VTDescKey(22)
	Local cKey24  := VTDescKey(24)
	Local cKey21  := VTDescKey(21)
	Local bKey04  := VTSetKey(04)
	Local bKey09  := VTSetKey(09)
	Local bKey12  := VTSetKey(12)
	Local bKey16  := VTSetKey(16)
	Local bKey22  := VTSetKey(22)
	Local bKey24  := VTSetKey(24)
	Local bKey21  := VTSetKey(21)
	Local lRetPE  := .T.
	Local lACD166VL     := ExistBlock("ACD166VL")
	Local lACD166VI     := ExistBlock("ACD166VI")
	Private cCodOpe     := CBRetOpe()
	Private cImp        := CBRLocImp("MV_IACD01")
	Private cNota
	Private lMSErroAuto := .F.
	Private lMSHelpAuto := .t.
	Private lExcluiNF   := .f.
	Private lForcaQtd   := GetMV("MV_CBFCQTD",,"2") =="1"
	Private lEtiProduto := .F.			//Indica se esta lendo etiqueta de produto
	Private cDivItemPv  := Alltrim(GetMV("MV_DIVERPV"))
	Private cPictQtdExp := PesqPict("CB8","CB8_QTDORI")
	Private cArmazem    := Space(Tamsx3("B1_LOCPAD")[1])
	Private cEndereco   := Space(TamSX3("BF_LOCALIZ")[1])
	Private nSaldoCB8   := 0
	Private cVolume     := Space(TamSX3("CB9_VOLUME")[1])
	Private cCodSep     := Space(TamSX3("CB9_ORDSEP")[1])

	If Type("cOrdSep")=="U"
		Private cOrdSep := Space(TamSX3("CB9_ORDSEP")[1])
	EndIf
	__aOldTela :={}
	__nSem := 0 // variavel static do fonte para controle de semaforo

	//If Empty(cCodOpe)
	//	VTAlert("Operador nao cadastrado","Aviso",.T.,4000,3) //"Operador nao cadastrado"###"Aviso"
	//	Return 10 // valor necessario para finalizar o acv170
	//EndIf

	VTClear()
	@ 0,0 VtSay "Conferencia"

	If ! CBSolCB7(nOpc,{|| VldCodSep()})
		Return MSCBASem() // valor necessario para finalizar o acv170 e liberar o semaforo
	EndIf

	If Empty(cOrdSep)
		cCodSep := CB7->CB7_ORDSEP
	Else
		cCodSep := cOrdSep
	EndIf

	IniProcesso()

	cAliasCB8 := GetNextAlias()
	_cQuery := " SELECT CB8_ORDSEP AS OrdSep, R_E_C_N_O_ AS REG FROM CB8010 CB8 "
	_cQuery += " WHERE CB8_FILIAL = '"+xFilial("CB8")+"' "
	_cQuery += " AND CB8_ORDSEP = '"+cCodSep+"' "
	_cQuery += " AND CB8.D_E_L_E_T_ <> '*' "
	_cQuery += " ORDER BY CB8_PROD "
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _CQUERY), cAliasCB8, .f., .t.)
	While (cAliasCB8)->(!Eof())
		CB8->(dbGoTo((cAliasCB8)->REG))
		If Empty(CB8->CB8_SALDOS) // ja separado
			(cAliasCB8)->(DbSkip())
			Loop
		EndIf
		//If !Empty(CB8->CB8_OCOSEP) .And. Alltrim(CB8->CB8_OCOSEP) $ cDivItemPv // com ocorrencia
		//	(cAliasCB8)->(DbSkip())
		//	Loop
		//EndIf
		//If ! Volume(Empty(cVolume))
		//	If VTYesNo("Confirma a saida?","Atencao",.T.) //"Confirma a saida?"###"Atencao"
		//		Exit
		//	EndIf
		//	Loop
		//EndIf
		//If !Tela()
		//	Exit
		//EndIf
		VTSetKey(16,{|| PulaItem()},"Pula") //"Pula"

		VTSetKey(04,{|| ACDV210() },"Div.Etiqueta") //"Div.Etiqueta"
		VTSetKey(12,{|| ACDV240() },"Div.Pallet") //"Div.Pallet"

		If ! EtiProduto()
			Exit
		EndIf

		VTSetKey(16,Nil)
	EndDo
	(cAliasCB8)->(DbCloseArea())

	vtsetkey(04,bKey04,cKey04)
	vtsetkey(09,bKey09,cKey09)
	vtsetkey(12,bKey12,cKey12)
	vtsetkey(16,bKey16,cKey16)
	vtsetkey(22,bKey22,cKey22)
	vtsetkey(21,bKey21,cKey21)
	MSCBASem() // valor necessario para finalizar o acv170 e liberar o semaforo
Return FimProcess(,cOrdSep)

Static Function Separou(cOrdSep)
	Local lRet:= .t.
	Local lV166SPOK
	Local aCB8	:= CB8->(GetArea())

	CB8->(DBSetOrder(1))
	CB8->(DbSeek(xFilial("CB8")+cOrdSep))
	While CB8->(! Eof() .and. CB8_FILIAL+CB8_ORDSEP == xFilial("CB8")+cOrdSep)
		If !Empty(CB8->CB8_OCOSEP) .AND. Alltrim(CB8->CB8_OCOSEP) $ cDivItemPv
			CB8->(DbSkip())
			Loop
		EndIf
		If CB8->CB8_SALDOS > 0
			lRet:= .f.
			Exit
		EndIf
		CB8->(DbSkip())
	EndDo
	If ExistBlock("V166SPOK")
		lV166SPOK:= ExecBlock("V166SPOK",.f.,.f.)
		If(ValType(lV166SPOK)=="L",lRet:= lV166SPOk,lRet)
		EndIf
		CB8->(RestArea(aCB8))
		Return(lRet)

Static Function IniProcesso()
	RecLock("CB7",.f.)
// AJUSTE DO STATUS
	If CB7->CB7_STATUS == "0" .or. Empty(CB7->CB7_STATUS) // nao iniciado
		CB7->CB7_STATUS := "1"  // em separacao
		CB7->CB7_DTINIS := dDataBase
		CB7->CB7_HRINIS := StrTran(Time(),":","")
	EndIf
	CB7->CB7_STATPA := " "  // se estiver pausado tira o STATUS  de pausa
	CB7->CB7_CODOPE := cCodOpe
	CB7->(MsUnlock())
Return

Static Function FimProcess(lApp,cOrdSep)
	Local lDiverg := .f.
	Local lRet    := .t.
	Local nSai    := 1
	Local cStatus := "2"
	Local lCloseOp := .F.
	Local lACDOCSE := SuperGetMV("MV_ACDOCSE",.F.,"S")=="S"
	Default 	lApp	:= .F.
	If lApp
		cDivItemPv  := Alltrim(GetMV("MV_DIVERPV"))
	Endif

	If !Empty(CB7->CB7_OP) .Or. CBUltExp(CB7->CB7_TIPEXP) $ "00*01*"
		cStatus  := "9"
	EndIf

//  inicio esta implemntacao dever ser melhor analisada
	If	CB7->CB7_ORIGEM == "1" .And. CB7->CB7_DIVERG == "1"
		CB8->(DbSetOrder(1))
		CB8->(DbSeek(xFilial("CB8")+CB7->CB7_ORDSEP))
		While CB8->(!Eof() .and. CB8_FILIAL == FWxFilial( 'CB8' ) .And. CB8_ORDSEP == CB7->CB7_ORDSEP)
			If	Empty(CB8->CB8_OCOSEP)
				CB8->(DbSkip())
				Loop
			Endif
			If	!(AllTrim(CB8->CB8_OCOSEP) $ cDivItemPv) .And. lACDOCSE
				RecLock("CB8",.f.)
				CB8->CB8_OCOSEP:= " "
				CB8->(MsUnlock())
			Else
				lDiverg:= .t.
			EndIf

			CB8->(DbSkip())
		EndDo
		If	!lDiverg
			RecLock("CB7",.f.)
			CB7->CB7_DIVERG := " "
			CB7->(MsUnlock())
		EndIf
	EndIf
//  fim  esta implemntacao dever ser melhor analisada

	If Separou(cOrdSep)
		If "07" $ CB7->CB7_TIPEXP
			If !(lRet:=RequisitOP())
				Reclock("CB7",.f.)
				CB7->CB7_STATUS := "1"  // separando
				CB7->CB7_STATPA := "1"  // Em pausa
				CB7->CB7_DTFIMS := Ctod("  /  /  ")
				CB7->CB7_HRFIMS := "     "
				nSai := 10
				If !lApp
					VTAlert("Problemas na Requisicao dos itens","Aviso",.t.,4000,3) //"Problemas na Requisicao dos itens"###"Aviso"
				Endif
			EndIf
		EndIf
		If lRet
			Reclock("CB7",.f.)
			CB7->CB7_STATUS := '9'   //  "2" -- separacao finalizada
			CB7->CB7_STATPA := " "
			CB7->CB7_DTFIMS := dDataBase
			CB7->CB7_HRFIMS := StrTran(Time(),":","")
		EndIf
		//-- Ponto de entrada no final da separacao
		If ExistBlock("ACD166FM")
			ExecBlock("ACD166FM")
		EndIf
		If CB7->CB7_STATUS == "2" .OR. CB7->CB7_STATUS == "9"
			IF 	UsaCb0("01")
				CB8->(DbSetOrder(1))
				CB8->(DbGotop())
				If CB8->(DbSeek(xFilial("CB8")+CB7->CB7_ORDSEP))
					CB9->(Dbsetorder(1))
					CB9->(Dbgotop())
					CB9->(Dbseek(xFilial('CB9')+CB7->CB7_ORDSEP))
					while !CB9->(EOF()) .and. CB9->CB9_FILIAL+CB9->CB9_ORDSEP == xfilial('CB9')+CB7->CB7_ORDSEP
						CB0->(Dbsetorder(1))
						CB0->(Dbgotop())
						If CB0->(Dbseek(xFilial('CB0')+CB9->CB9_CODETI))
							Reclock("CB0",.F.)
							CB0->CB0_NFSAI := CB8->CB8_NOTA
							CB0->CB0_SERIES:= CB8->CB8_SERIE
							CB0->(MsUnlock())
						EndIf
						CB9->(Dbskip())
					endDo
				EndIF
			EndIf
			If !lApp
				VTAlert("Processo de separacao finalizado","Aviso",.t.,4000)  //"Processo de separacao finalizado"###"Aviso"
			EndIf
		EndIf
	Else
		If !lDiverg .AND. ACDGet170() .AND. ;
				VTYesNo("Ainda existem itens nao separados. Deseja separalos agora?","Atencao",.T.) //"Ainda existem itens nao separados. Deseja separalos agora?"###"Atencao"
			nSai := 0
		Else
			Reclock("CB7",.f.)
			CB7->CB7_STATUS := "1"  // separando
			CB7->CB7_STATPA := "1"  // Em pausa
			CB7->CB7_DTFIMS := Ctod("  /  /  ")
			CB7->CB7_HRFIMS := "     "
			nSai := 10
		EndIf
	EndIf
	CB7->(MsUnlock())

	If CB7->CB7_ORIGEM == "3" //Ordem de Separacao
		CB8->( dbSetOrder( 1 ) )
		CB8->( dbSeek( FWxFilial( "CB8" ) + CB7->CB7_ORDSEP ) )
		While CB8->( !Eof() ) .And. CB8->CB8_FILIAL == FWxFilial( 'CB8' ) .And. CB8->CB8_ORDSEP == CB7->CB7_ORDSEP
			If CB8->CB8_SALDOS == 0
				lCloseOp := .T.
			Else
				lCloseOp := .F.
				Exit
			EndIf
			CB8->( dbSkip() )
		EndDo

		SC2->(DbSetOrder(1))
		If SC2->(DbSeek(xFilial("SC2")+CB7->CB7_OP))
			RecLock("SC2",.F.)
			SC2->C2_ORDSEP:= IIf( lCloseOp, CB7->CB7_ORDSEP, CriaVar( 'C2_ORDSEP', .F. ) ) // Limpa Ordem de Separacao p/ que possa ser possivel a separacao parcial das mesmas.
			SC2->(MsUnlock())
		EndIf

	EndIf

//Se existir divergencia estorna o item do pedido
	EstItemPv()
	If CB7->CB7_STATUS == "2"
		If !lApp
			VTAlert("Processo de separacao finalizado","Aviso",.t.,4000)  //"Processo de separacao finalizado"###"Aviso"
		Endif
	EndIf
	CBLogExp(cOrdSep)

	If	ExistBlock("ACD166FI")
		ExecBlock("ACD166FI",.F.,.F.)
	Endif

//Verifica se esta sendo chamado pelo ACDV170 e se existe um avanco
//ou retrocesso forcado pelo operador
	If ACDGet170() .AND. A170AvOrRet() .AND. A170SLProc()
		If CB7->CB7_STATUS=="1" //Ainda esta separando
			nSai := 0
		Else
			nSai := A170ChkRet()
		EndIf
	EndIf
Return nSai
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ AglutCB8   ³ Autor ³ ACD                 ³ Data ³ 27/01/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Funcao que retorna o valor aglutinado de um produto confor-³±±
±±³          ³ parametros informados.                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function AglutCB8(cOrdSep,cArm,cEnd,cProd,cLote,cSLote,cNumSer)
	Local nRecnoCB8:= CB8->(Recno())
	Local nSaldo:=0

	CB8->(DbSetOrder(7))
	CB8->(DbSeek(xFilial("CB8")+cCodSep+cArm))
	While ! CB8->(Eof()) .and. CB8->(CB8_FILIAL+CB8_ORDSEP+CB8_LOCAL==xFilial("CB8")+cCodSep+cArm)
		If ! CB8->(CB8_PROD+CB8_LOTECT+CB8_NUMLOT+CB8_NUMSER) ==cProd+cLote+cSLote+cNumSer
			CB8->(DbSkip())
			Loop
		EndIf
		If Empty(CB7->CB7_PRESEP) .and. CB8->CB8_LCALIZ <> cEnd
			CB8->(DbSkip())
			Loop
		EndIf
		If Empty(CB8->CB8_SALDOS) // ja separado
			CB8->(DbSkip())
			Loop
		EndIf
		nSaldo +=CB8->CB8_SALDOS
		CB8->(DbSkip())
	EndDo
	CB8->(DbGoto(nRecnoCB8))
Return nSaldo

Static Function EtiProduto()
	Local cEtiProd 	:= Space(TamSx3("B1_DUNCAIX")[1])
	Local nQtde 	:= 1
	Local bKey16 	:= VtSetKey(16)
	Local lDiverge 	:= .F.
	lEtiProduto := .T.

	VtSetKey(16,{||  lDiverge:= .t.,VtKeyboard(CHR(27)) },"Pula Item")  // CTRL+P //"Pula Item"

	While .t.
		VtClear()
		If Select("_TRB01") # 0
			_TRB01->(dbCloseArea())
		EndIf
		_cQuery := " SELECT SUM(CB8_SALDOS) AS SALDO FROM CB8010 CB8 "
		_cQuery += " WHERE CB8_FILIAL = '"+xFilial("CB8")+"' "
		_cQuery += " AND CB8_ORDSEP = '"+cCodSep+"' "
		_cQuery += " AND CB8_SALDOS > 0 "
		_cQuery += " AND CB8.D_E_L_E_T_ <> '*' "
		DbUseArea(.t., 'TOPCONN', TcGenQry (,, _CQUERY), "_TRB01", .f., .t.)
		DbSelectArea("_TRB01")
		DbGoTop()
		If _TRB01->(!Eof()) .And. _TRB01->SALDO == 0
			VtAlert("Ordem de Separacao Finalizada","Aviso",.t.,4000,4)
			RecLock("CB7", .F.)
			CB7->CB7_STATUS := '9'
			MsUnlock()
			Return .F.
		EndIf
		DbSelectArea("_TRB01")
		_TRB01->(DbCloseArea())

		@ 0,0 VTSay "Leia a Etiqueta" //"Leia o produto"
		@ 1,0 VTSay "Qtde " VtGet nQtde pict cPictQtdExp valid nQtde > 0 when (lForcaQtd .or. VtLastkey()==5) // //"Qtde "
		@ 2,0 VTGet cEtiProd pict "@!" VALID VTLastkey() == 5 .or. VldProduto(NIL,cEtiProd,nQtde)
		VTRead()
		VtSetKey(16, bKey16,"")

		If Select("_TRB01") # 0
			_TRB01->(dbCloseArea())
		EndIf
		_cQuery := " SELECT SUM(CB8_SALDOS) AS SALDO FROM CB8010 CB8 "
		_cQuery += " WHERE CB8_FILIAL = '"+xFilial("CB8")+"' "
		_cQuery += " AND CB8_ORDSEP = '"+cCodSep+"' "
		_cQuery += " AND CB8_SALDOS > 0 "
		_cQuery += " AND CB8.D_E_L_E_T_ <> '*' "
		DbUseArea(.t., 'TOPCONN', TcGenQry (,, _CQUERY), "_TRB01", .f., .t.)
		DbSelectArea("_TRB01")
		DbGoTop()
		If _TRB01->(!Eof()) .And. _TRB01->SALDO == 0
			VtAlert("Ordem de Separacao Finalizada","Aviso",.t.,4000,4)
			RecLock("CB7", .F.)
			CB7->CB7_STATUS := '9'
			MsUnlock()
			Return .F.
		EndIf
		DbSelectArea("_TRB01")
		_TRB01->(DbCloseArea())
		// tratamento de ocorrencia pular o item
		If VTLastkey() == 27
			//Verifica se esta sendo chamado pelo ACDV170 e se existe um avanco
			//ou retrocesso forcado pelo operador
			If ACDGet170() .AND. A170AvOrRet()
				Return .F.
			EndIf
			If VTYesNo("Confirma a saida?","Atencao",.T.) //"Confirma a saida?"###"Atencao"
				Return .f.
			Else
				Loop
			Endif
		Endif

		Exit
	Enddo
	lEtiProduto := .F.
Return .t.

Static Function EtiCaixa()
	Local cEtiqCaixa := Space(TamSx3("CB0_CODET2")[1])
	IF !Type("lVT100B") == "L"
		Private lVT100B := .F.
	EndIf

	While .t.
		@ 6,0 VTSay "Leia a caixa" //"Leia a caixa"
		@ 7,0 VtGet cEtiqCaixa pict "@!" Valid VldCaixa(cEtiqCaixa)
		VTRead
		// tratamento de ocorrencia pular o item
		If VTLastkey() == 27
			//Verifica se esta sendo chamado pelo ACDV170 e se existe um avanco
			//ou retrocesso forcado pelo operador
			If ACDGet170() .AND. A170AvOrRet()
				Return .F.
			EndIf

			If VTYesNo("Confirma a saida?","Atencao",.T.) //"Confirma a saida?"###"Atencao"
				Return .f.
			Else
				Loop
			Endif
		Endif
		Exit
	Enddo
Return .t.
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ EtiAvulsa  ³ Autor ³ ACD                 ³ Data ³ 27/01/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Leitura da etiqueta avulsa                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function EtiAvulsa()
	Local cEtiqAvulsa:= Space(TamSx3("CB0_CODET2")[1])
	IF !Type("lVT100B") == "L"
		Private lVT100B := .F.
	EndIf
	While .t.
		@ 6,0 VTClear to 7,19
		@ 6,0 VTSay "Leia a etiq. avulsa" //"Leia a etiq. avulsa"
		@ 7,0 VtGet cEtiqAvulsa pict "@!" Valid VldEtiqAvulsa(cEtiqAvulsa)
		VTRead()
		// tratamento de ocorrencia pular o item
		If VTLastkey() == 27
			//Verifica se esta sendo chamado pelo ACDV170 e se existe um avanco
			//ou retrocesso forcado pelo operador
			If ACDGet170() .AND. A170AvOrRet()
				Return .F.
			EndIf
			If VTYesNo("Confirma a saida?","Atencao",.T.) //"Confirma a saida?"###"Atencao"
				Return .f.
			Else
				Loop
			Endif
		Endif
		Exit
	Enddo
Return .t.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ GravaCB9 ³ Autor ³ ACD                   ³ Data ³ 28/01/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Expedicao                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function GravaCB9(nQtde,cEndNew,cLoteNew,cSLoteNew,cCodCB0,cNumSerNew,cSequen,lApp)
	Default cCodCB0 := Space(10)

	If lApp
		cVolume := ''
	Endif
	CB9->(DbSetOrder(10))
	If !CB9->(DbSeek(xFilial("CB9")+CB8->(CB8_ORDSEP+CB8_ITEM+CB8_PROD+CB8_LOCAL+CB8_LCALIZ+cLoteNew+cSLoteNew+CB8_LOTECT+CB8_NUMLOT+CB8_NUMSER+cVolume+cCodCB0+CB8_PEDIDO)))
		RecLock("CB9",.T.)
		CB9->CB9_FILIAL := xFilial("CB9")
		CB9->CB9_ORDSEP := CB7->CB7_ORDSEP
		CB9->CB9_CODETI := cCodCB0
		CB9->CB9_PROD   := CB8->CB8_PROD
		CB9->CB9_CODSEP := CB7->CB7_CODOPE
		CB9->CB9_ITESEP := CB8->CB8_ITEM
		CB9->CB9_SEQUEN := cSequen
		CB9->CB9_LOCAL  := CB8->CB8_LOCAL
		CB9->CB9_LCALIZ := cEndNew
		CB9->CB9_LOTECT := cLoteNew
		CB9->CB9_NUMLOT := cSLoteNew
		CB9->CB9_NUMSER := cNumSerNew
		CB9->CB9_LOTSUG := CB8->CB8_LOTECT
		CB9->CB9_SLOTSU := CB8->CB8_NUMLOT
		CB9->CB9_NSERSU := cNumSerNew
		CB9->CB9_PEDIDO := CB8->CB8_PEDIDO

		If '01' $ CB7->CB7_TIPEXP .Or. !Empty(cVolume)
			If !('02' $ CB7->CB7_TIPEXP)
				CB9->CB9_VOLUME := cVolume
			Else
				CB9->CB9_SUBVOL := cVolume
			EndIf
		EndIf

	Else
		RecLock("CB9",.F.)
	EndIf
	CB9->CB9_QTESEP += nQtde
	CB9->CB9_STATUS := "1"  // separado
	CB9->(MsUnlock())

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³GrvEstCB9 ³ Autor ³ ACD                   ³ Data ³ 28/01/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Estorna CB9                                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function GrvEstCB9(nQtde)
	Local nDevQtd := 0
	Local cProd	  := CB9->CB9_PROD
	Local cArm 	  := CB9->CB9_LOCAL
	Local cEnd 	  := CB9->CB9_LCALIZ
	Local cLote   := CB9->CB9_LOTECT
	Local cSLote  := CB9->CB9_NUMLOT
	Local cNumSer := CB9->CB9_NUMSER
	Local cVolAux := CB9->CB9_VOLUME

	If nQtde <= CB9->CB9_QTESEP
		//Devolve item(s) ja separados para o CB8
		DevItemCB8(nQtde)

		//Atualiza item(s) separados
		RecLock("CB9",.F.)
		CB9->CB9_QTESEP -= nQtde
		If Empty(CB9->CB9_QTESEP)
			CB9->(DbDelete())
		EndIf
		CB9->(MsUnlock())
	Else
		CB9->(DbSetOrder(9))
		CB9->(DbSeek(xFilial("CB9")+cCodSep+cProd+cArm))
		While CB9->(! Eof() .and. CB9_FILIAL+CB9_ORDSEP+CB9_PROD+CB9_LOCAL == xFilial("CB9")+cCodSep+cProd+cArm)
			If Empty(CB7->CB7_PRESEP) .AND. CB9->CB9_LCALIZ <> cEnd
				CB9->(DbSkip())
				Loop
			EndIf
			If ! CB9->(CB9_LOTECT+CB9_NUMLOT+CB9_NUMSER+CB9_VOLUME) ==cLote+cSLote+cNumSer+cVolAux
				CB9->(DbSkip())
				Loop
			EndIf
			If Empty(nQtde)
				Exit
			EndIf
			If Empty(CB9->CB9_QTESEP) // ja devolvido
				CB9->(DbSkip())
				Loop
			EndIf

			If nQtde <= CB9->CB9_QTESEP
				nDevQtd := nQtde
				nQtde	  := 0
			Else
				nDevQtd := CB9->CB9_QTESEP
				nQtde   -= nDevQtd
			EndIf

			If !DevItemCB8(nDevQtd)
				VTAlert("Item separado nao localizado!","Aviso",.T.,4000,3) //"Item separado nao localizado!"###"Aviso"
				CB9->(DbSetOrder(12))
				CB9->(DbSeek(xFilial("CB9")+cOrdSep))
				Return
			EndIf

			RecLock("CB9",.F.)
			CB9->CB9_QTESEP -= nDevQtd
			If Empty(CB9->CB9_QTESEP)
				CB9->(DbDelete())
			EndIf
			CB9->(MsUnlock())
		EndDo
	EndIf

	RecLock("CB7",.F.)
	CB7->CB7_STATUS := "1"
	CB7->(MsUnlock())
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o	 ³DevItemCB8  ³ Autor ³ ACD                 ³ Data ³ 16/02/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Devolve Items separados para o itens a separar CB8         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function DevItemCB8(nQtde)
	Local aCB8 := CB8->(GetArea())

	CB8->(DbSetOrder(4))
	If !CB8->(DbSeek(xFilial("CB8")+CB9->(CB9_ORDSEP+CB9_ITESEP+CB9_PROD+CB9_LOCAL+CB9_LCALIZ+CB9_LOTECT+CB9_NUMLOT+CB9_NUMSER)))
		CB8->(RestArea(aCB8))
		Return .F.
	EndIf

	While CB8->(!Eof() .AND. ;
			CB8_FILIAL+CB8_ORDSEP+CB8_ITEM+CB8_PROD+CB8_LOCAL+CB8_LCALIZ+CB8_LOTECT+CB8_NUMLOT+CB8_NUMSER ==;
			xFilial("CB8")+CB9->(CB9_ORDSEP+CB9_ITESEP+CB9_PROD+CB9_LOCAL+CB9_LCALIZ+CB9_LOTECT+CB9_NUMLOT+CB9_NUMSER))
		If CB8->CB8_PEDIDO # CB9->CB9_PEDIDO
			CB8->(DbSkip())
			Loop
		EndIf

		RecLock("CB8")
		CB8->CB8_SALDOS := CB8->CB8_SALDOS + nQtde
		If "01" $ CB7->CB7_TIPEXP
			CB8->CB8_SALDOE := CB8->CB8_SALDOE + nQtde
		EndIf
		CB8->(MsUnlock())
		CB8->(DbSkip())
	EndDo
//Restaura Ambiente
	CB8->(RestArea(aCB8))
Return .T.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o	 ³ Informa    ³ Autor ³ ACD                 ³ Data ³ 31/01/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Mostra produtos que ja foram lidos                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function Informa()
	Local aCab,aSize,aSave := VTSAVE()
	Local aTemp:={}
	Local nTam

	If Empty(cOrdSep)
		Return .f.
	Endif
	VTClear()
	If UsaCB0("01")
		aCab  := {"Produto","Quantidade","Armazem","Endereco","Lote","Sub-Lote","Volume","Sub-Volume","Num.Serie","Id Etiqueta"} //"Produto"###"Quantidade"###"Armazem"###"Endereco"###"Lote"###"Sub-Lote"###"Volume"###"Sub-Volume"###"Num.Serie"###"Id Etiqueta"
	Else
		aCab  := {"Produto","Quantidade","Armazem","Endereco","Lote","Sub-Lote","Volume","Sub-Volume","Num.Serie"} //"Produto"###"Quantidade"###"Armazem"###"Endereco"###"Lote"###"Sub-Lote"###"Volume"###"Sub-Volume"###"Num.Serie"
	EndIf
	nTam := len(aCab[2])
	If nTam < len(Transform(0,cPictQtdExp))
		nTam := len(Transform(0,cPictQtdExp))
	EndIf
	If UsaCB0("01")
		aSize := {15,nTam,7,10,10,8,10,10,20,12}
	Else
		aSize := {15,nTam,7,10,10,8,10,10,20}
	Endif
	CB9->(DbSetOrder(6))
	CB9->(DbSeek(xFilial("CB9")+cOrdSep))
	While CB9->(! Eof() .and. CB9_FILIAL+CB9_ORDSEP == xFilial("CB9")+cOrdSep)
		If UsaCB0("01")
			aadd(aTemp,{CB9->CB9_PROD,Transform(CB9->CB9_QTESEP,cPictQtdExp),CB9->CB9_LOCAL,CB9->CB9_LCALIZ,CB9->CB9_LOTECT,CB9->CB9_NUMLOT,CB9->CB9_VOLUME,CB9->CB9_SUBVOL,CB9->CB9_NUMSER,CB9->CB9_CODETI})
		Else
			aadd(aTemp,{CB9->CB9_PROD,Transform(CB9->CB9_QTESEP,cPictQtdExp),CB9->CB9_LOCAL,CB9->CB9_LCALIZ,CB9->CB9_LOTECT,CB9->CB9_NUMLOT,CB9->CB9_VOLUME,CB9->CB9_SUBVOL,CB9->CB9_NUMSER})
		Endif
		CB9->(DbSkip())
	EndDo

	VTaBrowse(,,,VtMaxCol(),aCab,aTemp,aSize)
	VtRestore(,,,,aSave)
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ Volume   ³ Autor ³ ACD                   ³ Data ³ 31/01/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Geracao de volume para Embalagem simultanea                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function Volume(lForcaEntrada)
	Local aTela
	Local cVolAnt
	Default lForcaEntrada := .T.

	cVolAnt := cVolume
	aTela   := VTSave()
	VTClear()
	cVolume := Space(20)
	@ 0,0 VTSay "Embalagem" //"Embalagem"
	@ 1,0 VtSay "Leia o volume:" //"Leia o volume:"
	@ 2,0 VtGet cVolume Pict "@!" Valid VldVolume()
	@ 4,0 VtSay "Tecle ENTER para" //"Tecle ENTER para"
	@ 5,0 VtSay "novo volume.    " //"novo volume.    "
	VTRead
	VTRestore(,,,,aTela)
	cVolume := Padr(cVolume,10)
	If VTLastkey() == 27
		cVolume := cVolAnt
		Return .f.
	EndIf
Return .t.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ VldVolume³ Autor ³ Anderson Rodrigues    ³ Data ³ 25/11/03 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Validacao da Geracao do Volume                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static function VldVolume()
	Local cCodEmb := Space(3)
	Local aRet    := {}
	Local aTela   := {}
	Local cRet
	Local lACD166V1
	Private cCodVol
	IF !Type("lVT100B") == "L"
		Private lVT100B := .F.
	EndIf

	If Empty(cVolume)
		aTela := VTSave()
		VtClear()
		@ 1,0 VtSay "Digite o codigo do" //"Digite o codigo do"
		@ 2,0 VtSay "tipo de embalagem" //"tipo de embalagem"
		@ 3,0 VTGet cCodEmb pict "@!"  Valid VldEmb(cCodEmb) F3 "CB3"
		VTRead()

		If VTLastkey() == 27
			VtRestore(,,,,aTela)
			VtKeyboard(Chr(20))  // zera o get
			Return .f.
		EndIf
		VtRestore(,,,,aTela)
		If CB5SetImp(cImp,.t.) .and. ExistBlock("IMG05")
			cCodVol := CB6->(GetSX8Num("CB6","CB6_VOLUME"))
			ConfirmSX8()
			VTAlert("Imprimindo etiqueta de volume ","Aviso",.T.,2000) //"Imprimindo etiqueta de volume "###"Aviso"
			ExecBlock("IMG05",.F.,.F.,{cCodVol,CB7->CB7_PEDIDO,CB7->CB7_NOTA,CB7->CB7_SERIE})
			MSCBCLOSEPRINTER()
			CB6->(RecLock("CB6",.T.))
			CB6->CB6_FILIAL := xFilial("CB6")
			CB6->CB6_VOLUME := cCodVol
			CB6->CB6_PEDIDO := CB7->CB7_PEDIDO
			CB6->CB6_NOTA   := CB7->CB7_NOTA
			CB6->CB6_SERIE  := CB7->CB7_SERIE
			CB6->CB6_TIPVOL := CB3->CB3_CODEMB
			CB6->CB6_STATUS := "1"   // ABERTO
			CB6->(MsUnlock())
		EndIf
		Return .f.
	Else
		If UsaCB0("05")
			aRet:= CBRetEti(cVolume)
			If Empty(aRet)
				VtAlert("Etiqueta invalida","Aviso",.t.,4000,3) //"Etiqueta invalida"###"Aviso"
				VtKeyboard(Chr(20))  // zera o get
				Return .f.
			EndIf
			cCodVol:= aRet[1]
		Else
			cCodVol:= cVolume
		Endif
		CB6->(DBSetOrder(1))
		If ! CB6->(DbSeek(xFilial("CB6")+cCodVol))
			VtAlert("Codigo de volume nao cadastrado","Aviso",.t.,4000,3) //"Codigo de volume nao cadastrado"###"Aviso"
			VtKeyboard(Chr(20))  // zera o get
			Return .f.
		EndIf
		If CB7->CB7_ORIGEM == "1"
			If ! CB6->CB6_PEDIDO == CB7->CB7_PEDIDO
				VtAlert("Volume pertence ao pedido "+CB6->CB6_PEDIDO,"Aviso",.t.,4000,3) //"Volume pertence ao pedido "###"Aviso"
				VtKeyboard(Chr(20))  // zera o get
				Return .f.
			EndIf
		ElseIf CB7->CB7_ORIGEM == "2"
			If ! CB6->(CB6_NOTA+CB6_SERIE) == CB7->(CB7_NOTA+CB7_SERIE)
				VtAlert("Volume pertence a nota "+CB6->(CB6_NOTA+"-"+CB6_SERIE),"Aviso",.t.,4000,3) //"Volume pertence a nota "###"Aviso"
				VtKeyboard(Chr(20))  // zera o get
				Return .f.
			EndIf
		EndIf
	EndIf
	cVolume:= CB6->CB6_VOLUME
Return .t.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ VldEmb   ³ Autor ³ ACD                   ³ Data ³ 31/01/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Validacao do Tipo de Embalagem                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function VldEmb(cEmb)
	If Empty(cEmb)
		Return .f.
	EndIf
	CB3->(DbSetOrder(1))
	If ! CB3->(DbSeek(xFilial("CB3")+cEmb))
		VtAlert("Embalagem nao cadastrada","Aviso",.t.,4000,3) //"Embalagem nao cadastrada"###"Aviso"
		VtKeyboard(Chr(20))  // zera o get
		Return .F.
	EndIf
Return .t.

Static Function VldCodSep()
	Local lRet := .T.

	If Empty(cOrdSep)
		VtKeyBoard(chr(23))
		Return .f.
	EndIf

	CB7->(DbSetOrder(1))
	If !CB7->(DbSeek(xFilial("CB7")+cOrdSep))
		VtAlert("Ordem de separacao nao encontrada.","Aviso",.t.,4000,3) //"Ordem de separacao nao encontrada."###"Aviso"
		VtKeyboard(Chr(20))  // zera o get
		Return .F.
	EndIf
	//If "09*" $ CB7->CB7_TIPEXP
	//	VtAlert(STR0073,STR0074,.t.,4000,3) //"Ordem de Pre-Separacao "###"Codigo Invalido"
	//	VtKeyboard(Chr(20))  // zera o get
	//	Return .F.
	//EndIf

	//If CB7->CB7_STATUS == "3"
	//	VtAlert(STR0075,"Aviso",.t.,4000,3) //"Ordem de separacao em processo de embalagem"###"Aviso"
	//	VtKeyboard(Chr(20))  // zera o get
	//	Return .F.
	//EndIf

	//If CB7->CB7_STATUS == "4"
	//	VtAlert(STR0076,"Aviso",.t.,4000,3) //"Ordem de separacao com embalagem finalizada"###"Aviso"
	//	VtKeyboard(Chr(20))  // zera o get
	//	Return .F.
	//EndIf

	//If CB7->CB7_STATUS  == "5" .OR.  CB7->CB7_STATUS  == "6"
	//	VtAlert(STR0077,"Aviso",.t.,4000,3) //"Ordem de separacao possui Nota gerada"###"Aviso"
	//	VtKeyboard(Chr(20))  // zera o get
	//	Return .F.
	//EndIf

	//If CB7->CB7_STATUS  == "7"
	//	VtAlert(STR0078,"Aviso",.t.,4000,3) //"Ordem de separacao possui etiquetas oficiais de volumes"###"Aviso"
	//	VtKeyboard(Chr(20))  // zera o get
	//	Return .F.
	//EndIf

	//If CB7->CB7_STATUS  == "8"
	//	VtAlert(STR0079,"Aviso",.t.,4000,3) //"Ordem de separacao em processo de embarque"###"Aviso"
	//	VtKeyboard(Chr(20))  // zera o get
	//	Return .F.
	//EndIf

	//If !(!Empty(CB7->CB7_OP) .Or. CBUltExp(CB7->CB7_TIPEXP) $ "00*01*") .And. CB7->CB7_STATUS == "9"
	//	VtAlert(STR0080,"Aviso",.t.,4000,3) //"Ordem de separacao ja Embarcada"###"Aviso"
	//	VtKeyboard(Chr(20))  // zera o get
	//	Return .F.
	//EndIf

	//If CB7->CB7_STATPA == "1" .AND. CB7->CB7_CODOPE # cCodOpe  // SE ESTIVER EM SEPARACAO E PAUSADO SE DEVE VERIFICAR SE O OPERADOR E" O MESMO
	//	VtBeep(3)
	//	If ! VTYesNo(STR0081+CB7->CB7_CODOPE+STR0082,"Aviso",.T.) //"Ordem Separacao iniciada pelo operador "###". Deseja continuar ?"###"Aviso"
	//		VtKeyboard(Chr(20))  // zera o get
	//		Return .F.
	//	EndIf
	//EndIf

	If lRet .And. !MSCBFSem() //fecha o semaforo, somente um separador por ordem de separacao
		VtAlert("Ordem Separacao ja esta em andamento...!","Aviso",.t.,4000,3) //"Ordem Separacao ja esta em andamento...!"###"Aviso"
		VtKeyboard(Chr(20))  // zera o get
		Return .F.
	EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ VldEnd   ³ Autor ³ ACD                   ³ Data ³ 27/01/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Validacao do endereco                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
// nOpc = 1 --> Separacao
// nOpc = 2 --> Estorno da Separacao
// nOpc = 3 --> Devolucao da Separacao (Funcao EstEnd())
*/
Static Function VldEnd(cArmazem,cEndereco,cEtiqEnd,nOpc)
	Local cChave
	Local aRet
	Local aCB9
	Local nRecCB9
	Local lErro := .f.
	Default cEndereco :=""
	Default cEtiqEnd  :=""
	Default nOpc      := 1

	If nOpc == 1
		cChave := CB8->(CB8_LOCAL+CB8_LCALIZ)
	ElseIf nOpc == 3
		cChave := CB9->(CB9_LOCAL+CB9_LCALIZ)
	EndIf

	VtClearBuffer()
	If Empty(cArmazem+cEndereco+cEtiqEnd)
		If ! UsaCB0("02")
			VTGetSetFocus("cArmazem")
		EndIf
		Return .f.
	EndIf
	If UsaCB0("02")
		aRet := CBRetEti(cEtiqEnd,"02")
		If Empty(aRet)
			VtAlert("Etiqueta invalida","Aviso",.t.,4000,3) //"Etiqueta invalida"###"Aviso"
			VtKeyboard(Chr(20))  // zera o get
			Return .f.
		EndIf
		cArmazem  := aRet[2]
		cEndereco := aRet[1]
	EndIf

	If nOpc==2  //ESTORNO
		aCB9      := CB9->(GetArea())
		nRecCB9	 := CB9->(RecNo())
		CB9->(DbSetOrder(12))
		If CB9->(DbSeek(xFilial("CB9")+cOrdSep+cArmazem+cEndereco))
			Return .t.
		EndIf
		lErro := .t.
	Else
		If cArmazem+cEndereco <> cChave
			lErro := .t.
		EndIf
	EndIf

	If lErro
		VtAlert("Endereco invalido","Aviso",.t.,4000,3) //"Endereco invalido"###"Aviso"
		If UsaCB0("02")
			VTClearGet("cEtiqEnd")
		Else
			VTClearGet("cArmazem")
			VTClearGet("cEndereco")
			VTGetSetFocus("cArmazem")
		EndIf
		Return .f.
	EndIf

	If !CBEndLib(cArmazem,cEndereco) // verifica se o endereco esta liberado ou bloqueado
		VtAlert("Endereco Bloqueado.","Aviso",.t.,4000,3) //"Endereco Bloqueado."###"Aviso"
		If UsaCB0("02")
			VTClearGet("cEtiqEnd")
		Else
			VTClearGet("cArmazem")
			VTClearGet("cEndereco")
			VTGetSetFocus("cArmazem")
		EndIf
		Return .f.
	EndIf

Return .t.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³VldProduto³ Autor ³ ACD                   ³ Data ³ 27/01/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Validacao da etiqueta de produto com ou sem CB0            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function VldProduto(cEtiCB0,cEtiProd,nQtde)
	Local cCodCB0
	Local nP 		:= 0
	Local cEtiqueta
	Local aEtiqueta := {}
	Local aItensPallet:= {}
	Local lIsPallet := .T.
	Local cMsg 		:= ""
	Local lErrQTD 	:= .F.

	DEFAULT cEtiCB0   := Space(TamSx3("CB0_CODET2")[1])
	DEFAULT cEtiProd  := Space(48)
	DEFAULT nQtde     := 1

	cAliasSB1 := GetNextAlias()
	_cQuery := " SELECT B1_COD FROM SB1010 SB1 "
	_cQuery += " WHERE B1_FILIAL = '"+xFilial("SB1")+"' "
	_cQuery += " AND SB1.D_E_L_E_T_ <> '*' "
	_cQuery += " AND B1_DUNCAIX = '"+Alltrim(cEtiProd)+"' "
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _CQUERY), cAliasSB1, .f., .t.)
	If (cAliasSB1)->(!Eof())
		cEtiProd := (cAliasSB1)->B1_COD

		If __PulaItem
			Return .t.
		EndIf

		If Empty(cEtiCB0+cEtiProd)
			Return .f.
		EndIf


		aItensPallet := CBItPallet(cEtiProd)

		//If Len(aItensPallet) == 0
		//	If UsaCB0("01")
		//		aItensPallet:={cEtiCB0}
		//	Else
		//		aItensPallet:={cEtiProd}
		//	EndIf
		//	lIsPallet := .f.
		//EndIf

		Begin Sequence
			//For nP:= 1 to Len(aItensPallet)
			//cEtiqueta:= aItensPallet[nP]

			cCodCB0  := Space(10)
			//aEtiqueta := CBRetEtiEan(cEtiqueta)
			//If len(aEtiqueta) == 0
			//	cMsg := "Etiqueta invalida"  //"Etiqueta invalida"
			//	Break
			//Else
			_nConv := Posicione("SB1",1,xFilial("SB1")+cEtiProd,"SB1->B1_CONV")
			//EndIf
			nQtdeO := _nConv*nQtde
			nQtdeT := _nConv*nQtde
			_nReg := 0
			If Select("_TRB01") # 0
				_TRB01->(dbCloseArea())
			EndIf
			_cQuery := " SELECT SUM(CB8_SALDOS) AS SALDO, CB8.R_E_C_N_O_ AS REG FROM CB8010 CB8 "
			_cQuery += " WHERE CB8_FILIAL = '"+xFilial("CB8")+"' "
			_cQuery += " AND CB8_ORDSEP = '"+cCodSep+"' "
			_cQuery += " AND CB8_PROD = '"+cEtiProd+"' "
			_cQuery += " AND CB8_SALDOS > 0 "
			_cQuery += " AND CB8.D_E_L_E_T_ <> '*' "
			_cQuery += " GROUP BY CB8.R_E_C_N_O_
			DbUseArea(.t., 'TOPCONN', TcGenQry (,, _CQUERY), "_TRB01", .f., .t.)
			DbSelectArea("_TRB01")
			DbGoTop()
			If _TRB01->(Eof())
				cMsg := "Produto diferente"
				VtAlert(cMsg,"Aviso",.t.,4000,4)
				Break
			Else
				_nQtdSep := 0
				Do While _TRB01->(!Eof())
					_nQtdSep += _TRB01->SALDO
					_TRB01->(DbSkip())
				EndDo
				If _nQtdSep >= nQtdeT
					DbSelectArea("_TRB01")
					DbGoTop()
					Do While _TRB01->(!Eof())
						_nReg 	  := _TRB01->REG
						nSaldoCB8 := _TRB01->SALDO
						DbSelectArea("CB8")
						DbGoTo(_nReg)
						If ! CBProdLib(CB8->CB8_LOCAL,CB8->CB8_PROD)
							cMsg:=""
							Break
						EndIf
						If nSaldoCB8 < nQtdeT
							nQtdeO := nSaldoCB8
							nQtdeT -= nSaldoCB8
						Else
							nQtdeO := nQtdeT
							nQtdeT := 0
						EndIf
						RecLock("CB8",.F.)
						CB8->CB8_SALDOS -= nQtdeO
						CB8->(MsUnlock())
						If CB8->CB8_SALDOS > 0
							Reclock("CB7",.f.)
							CB7->CB7_STATUS := "1"  // inicio separacao
							CB7->(MsUnLock())
							//Else
							//Reclock("CB7",.f.)
							//CB7->CB7_STATUS := "9"  // Final separacao
							//CB7->(MsUnLock())
						EndIf
//felipe
						_TRB01->(DbSkip())
					EndDo
				Else
					cMsg 	:= "Quantidade maior que necessario"
					lErrQTD := .t.
					nQtde 	:= 1
					Break
				EndIf
			EndIf
			DbSelectArea("_TRB01")
			_TRB01->(DbCloseArea())
			//Next nP

			RECOVER
			//If ! Empty(cMsg)
				//VtAlert(cMsg,"Aviso",.t.,4000,4) //"Aviso"
			//EndIf
			VtClearGet("cEtiProd")
			VtGetSetFocus("cEtiProd")
			If !UsaCB0("01") .and. lForcaQtd .and. lErrQTD
				VtGetSetFocus("nQtde")
			EndIf
			Return .f.
		End Sequence
	Else
		VtAlert("DUN Invalido","Aviso",.t.,4000,4) //"Aviso"
	EndIf

Return .t.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ VldCaixa ³ Autor ³ ACD                   ³ Data ³ 27/01/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Rotina de validacao da leitura da etiq da caixa "granel"   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function VldCaixa(cEtiqCaixa,lEstEnd)
	Local aRet
	Default lEstEnd := .F.

	If Empty(cEtiqCaixa)
		Return .f.
	EndIf
	aRet := CBRetEti(cEtiqCaixa,"01")
	If Empty(aRet)
		VtAlert("Etiqueta invalida","Aviso",.t.,4000,3) //"Etiqueta invalida"###"Aviso"
		VtKeyboard(Chr(20))  // zera o get
		Return .F.
	EndIf
	If ! Empty(aRet[2])
		VtAlert("Etiqueta invalida","Aviso",.t.,4000,3) //"Etiqueta invalida"###"Aviso"
		VtKeyboard(Chr(20))  // zera o get
		Return .f.
	EndIf

	If lEstEnd
		If !(CB9->CB9_PROD == aRet[1])
			VtAlert("Etiqueta de produto diferente","Aviso",.t.,4000,3) //"Etiqueta de produto diferente"###"Aviso"
			VtKeyboard(Chr(20))  // zera o get
			Return .F.
		EndIf
		Return .T.
	EndIf

	If ! CBProdLib(CB8->CB8_LOCAL,CB8->CB8_PROD)
		VTKeyBoard(chr(20))
		Return .f.
	Endif
	If CB8->CB8_PROD <> aRet[1]
		VtAlert("Etiqueta de produto diferente","Aviso",.t.,4000,3) //"Etiqueta de produto diferente"###"Aviso"
		VtKeyboard(Chr(20))  // zera o get
		Return .f.
	EndIf
Return .t.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±
±±³Fun‡ao    ³VldEtiqAvulsa³ Autor ³ ACD                   ³ Data ³ 27/01/05 ³±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±
±±³Descri‡ao ³ Rotina de registro da etiqueta avulsa  qdo "granel"           ³±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±
±±³ Uso      ³ SIGAACD                                                       ³±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function VldEtiqAvulsa(cEtiqAvulsa,lEstEnd)
	Local nQE
	Local aEtiqueta:= {}
	Local cLote    := CB0->CB0_LOTE
	Local cSLote   := CB0->CB0_SLOTE
	Local nRecnoCb0:= CB0->(Recno())
	Default lEstEnd:= .F.

	If Empty(cEtiqAvulsa)
		Return .f.
	EndIf

	aEtiqueta:= CBRetEti(cEtiqAvulsa,"01")

	If lEstEnd //somente eh executado ao desfazer a separacao
		If Empty(aEtiqueta)
			VtAlert("Etiqueta invalida","Aviso",.t.,4000,3) //"Etiqueta invalida"###"Aviso"
			VtKeyboard(Chr(20))  // zera o get
			Return .f.
		EndIf
		nQtdLida := aEtiqueta[2]
		Return .t.
	EndIf

	If Len(aEtiqueta) > 0
		VtAlert("Etiqueta invalida","Aviso",.t.,4000,3) //"Etiqueta invalida"###"Aviso"
		VtKeyboard(Chr(20))  // zera o get
		CB0->(DbGoto(nRecnoCb0))
		Return .f.
	EndIf
	nQE  :=CBQtdEmb(CB8->CB8_PROD)
	If Empty(nQE)
		VtAlert("Quantidade invalida","Aviso",.t.,4000,3) //"Quantidade invalida"###"Aviso"
		VtKeyboard(Chr(20))  // zera o get
		CB0->(DbGoto(nRecnoCb0))
		Return .F.
	EndIf
	If nQE > nSaldoCB8
		VtAlert("Quantidade maior que solicitado","Aviso",.t.,4000,3) //"Quantidade maior que solicitado"###"Aviso"
		VtKeyboard(Chr(20))  // zera o get
		CB0->(DbGoto(nRecnoCb0))
		Return .f.
	EndIf
	If ! CBRastro(CB8->CB8_PROD,@cLote,@cSLote)
		VTKeyBoard(chr(20))
		CB0->(DbGoto(nRecnoCb0))
		Return .f.
	EndIf
	CB8->(CBGrvEti("01",{SB1->B1_COD,nQE,cCodSep,,,,,,CB8_LCALIZ,CB8_LOCAL,,,,,,cLote,cSLote,,,CB8_LOCAL,,,CB8_NUMSER,},Padr(cEtiqAvulsa,10)))
	If ! VldProduto(CB0->CB0_CODETI)
		RecLock("CB0",.f.)
		CB0->(DbDelete())
		CB0->(MSUnlock())
		CB0->(DbGoto(nRecnoCb0))
		Return .f.
	EndIf
Return .t.


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ PulaItem ³ Autor ³ ACD                   ³ Data ³ 18/02/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Pula Item gravando o codigo de ocorrencia.                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function PulaItem()
	Local i
	Local cChave	:= CB8->(CB8_LOCAL+CB8_LCALIZ+CB8_PROD+CB8_LOTECT+CB8_NUMLOT+CB8_NUMSER)
	Local cChSeek	:= CB8->(CB8_ORDSEP+CB8_ITEM+CB8_PROD+CB8_LOCAL+CB8_LCALIZ+CB8_LOTECT+CB8_NUMLOT+CB8_NUMSER)
	Local nRecCB8	:= CB8->(RecNo())
	Local aSvTela	:= {}
	Local aAreaCB8	:= CB8->(GetArea())
	IF !Type("lVT100B") == "L"
		Private lVT100B := .F.
	EndIf

	aSvTela := VtSave()
	cOcoSep := CB8->CB8_OCOSEP
	CB4->(DbSetOrder(1))
	CB4->(DbSeek(xFilial("CB4")+cOcoSep))
	VTClear
	@ 2,0 VTSay "Informe o codigo" //"Informe o codigo"
	@ 3,0 VTSay "da divergencia:" //"da divergencia:"
	@ 4,0 VtGet cOcoSep pict "@!" Valid VldOcoSep(cOcoSep,cChave) F3 "CB4"
	VtRead()
	VtRestore(,,,,aSvTela)
	__PulaItem := .F.
	If VtLastKey() == 27
		Return .t.
	EndIf
	CB8->(DBSETORDER(4))
	CB8->(DBGOTOP())
	CB8->(DbSeek(xFilial("CB8")+cChSeek))
	While CB8->(!Eof()) .AND. ;
			CB8->(CB8_FILIAL+CB8_ORDSEP+CB8_ITEM+CB8_PROD+CB8_LOCAL+CB8_LCALIZ+CB8_LOTECT+CB8_NUMLOT+CB8_NUMSER)==;
			xFilial("CB8")+cChSeek
		RecLock("CB8",.F.)
		CB8->CB8_OCOSEP := cOcoSep
		CB8->(MsUnlock())
		CB8->(DbSkip())
	EndDo
	CB8->(MsGoto(nRecCB8))

	If CB7->CB7_DIVERG # "1"   // marca divergencia na ORDEM DE SEPARACAO para que esta seja arrumada
		CB7->(RecLock("CB7"))
		CB7->CB7_DIVERG := "1"  // sim
		CB7->(MsUnlock())
	EndIf
	__PulaItem := .T.
	VtKeyboard(CHR(13))
	RestArea(aAreaCB8)
Return .t.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ VldOcoSep³ Autor ³ ACD                   ³ Data ³ 18/02/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Validacao do codigo de ocorrencia da separacao             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function VldOcoSep(cOcoSep,cChave)

	If Empty(cOcoSep)
		VtKeyBoard(chr(23))
	EndIf

	CB4->(DBSetOrder(1))
	If !CB4->(DbSeek(xFilial("CB4")+cOcoSep))
		VtAlert("Ocorrencia nao cadastrada","Aviso",.t.,4000,3) //"Ocorrencia nao cadastrada"###"Aviso"
		VtKeyboard(Chr(20))  // zera o get
		Return .F.
	EndIf

	If AllTrim(cOcoSep) $ cDivItemPv
		Return .T.
	EndIf

	If !CB8->(DbSeek(xFilial("CB8")+cOrdSep+cChave))
		VtAlert("Item nao localizado","Aviso",.t.,4000,3) //"Item nao localizado"###"Aviso"
		VtKeyboard(Chr(20))  // zera o get
		Return .F.
	EndIf

	While CB8->(!Eof() .AND. ;
			CB8_FILIAL+CB8_ORDSEP+CB8_LOCAL+CB8_LCALIZ+CB8_PROD+CB8_LOTECT+CB8_NUMLOT+CB8_NUMSER==;
			xFilial("CB8")+cOrdSep+cChave)
		If CB8->(CB8_QTDORI<>CB8_SALDOS)
			VtAlert("Esta ocorrencia exige o estorno dos itens lidos deste produto!","Aviso",.t.,4000,3) //"Esta ocorrencia exige o estorno dos itens lidos deste produto!"###"Aviso"
			VtKeyboard(Chr(20))  // zera o get
			Return .F.
		EndIf
		CB8->(DbSkip())
	EndDo
Return .t.

Static Function UltTela()
	Local aTela:= VTSave()
	If Len(__aOldTela) ==0
		Return
	EndIf
	VtClear()
	If ValType(__aOldTela[1])=="C"
		VTaChoice(,,,,__aOldTela)   //ultima tela da funcao endereco
	Else
		VTaBrowse(,,,,{"Separe",""},__aOldTela,{10,VtMaxCol()},,," ") // ultima tela da funcao tela() //"Separe"
	EndIf

	VtRestore(,,,,aTela)
Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ Estorna  ³ Autor ³ ACD                   ³ Data ³ 14/02/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Faz a devolucao do que foi separado                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function Estorna()
	Local cKey24  := VTDescKey(24)
	Local bKey24  := VTSetKey(24)
	Local nQtdSep := 0
	Local nQtdCX  := 0
	Local nQtdPE  := 0
	Local cUnidade:=""
	Local nRecCB8 := CB8->(RecNo())
	Local aTela   := VTSave()
	Local aTam    := TamSx3("CB8_QTDORI")
	Local lRet    := .f.
	IF !Type("lVT100B") == "L"
		Private lVT100B := .F.
	EndIf
	If Empty(cOrdSep)
		Return .f.
	Endif

	VTSetKey(24,nil)

	If !ExistCB9Sp(cOrdSep)
		VTAlert("Nao existe itens  a serem Estornados","Aviso",.T.,4000,3) //"Nao existe itens  a serem Estornados"###"Aviso"
	Else
		If UsaCB0("01")
			VtClear()
			If VtModelo()=="RF" .or. lVT100B // GetMv("MV_RF4X20")
				@ 0,0 VTSAY "Estorno" //"Estorno"
				@ 1,0 VTSay "Selecione:" //"Selecione:"
				nOpc:=VTaChoice(3,0,4,VTMaxCol(),{"Por Produto","Por Endereco"}) //"Por Produto"###"Por Endereco"
			Else
				@ 0,0 VTSAY "Estorno selecione:" //"Estorno selecione:"
				nOpc:=VTaChoice(1,0,1,VTMaxCol(),{"Por Produto","Por Endereco"}) //"Por Produto"###"Por Endereco"
			EndIf
			VtClearBuffer()
			If nOpc == 1
				lRet:= EstProd()
			ElseIf nOpc == 2
				lRet:= EstEnd()
			EndIf
		Else
			lRet:= EstEnd()
		Endif
	Endif
	VTkeyBoard(chr(13))
	VTRestore(,,,,aTela)
	If lEtiProduto
		//Atualizacao de valores
		CB8->(DbGoto(nRecCB8))

		nSaldoCB8 := CB8->(AglutCB8(CB8_ORDSEP,CB8_LOCAL,CB8_LCALIZ,CB8_PROD,CB8_LOTECT,CB8_NUMLOT,CB8_NUMSER))
		If GetNewPar("MV_OSEP2UN","0") $ "0 " // verifica se separa utilizando a 1 unidade de media
			nQtdSep := nSaldoCB8
			cUnidade:= If(nQtdSep==1,"item ","itens ") //"item "###"itens "
		Else                                          // ira separar por volume se possivel
			nQtdCX:= CBQEmb()
			If ExistBlock("CBRQEESP")
				nQtdPE:=ExecBlock("CBRQEESP",,,SB1->B1_COD) // ponto de entrada possibilitando ajustar a quantidade por embalagem
				nQtdCX:=If(ValType(nQtdPE)=="N",nQtdPE,nQtdCX)
			EndIf
			If nSaldoCB8/nQtdCX < 1
				nQtdSep := nSaldoCB8
				cUnidade:= If(nQtdSep==1,"item ","itens ") //"item "###"itens "
			Else
				nQtdSep := nSaldoCB8/nQTdCx
				cUnidade:= If(nQtdSep==1,"volume ","volumes ") //"volume "###"volumes "
			EndIf
		EndIf
		If VTModelo()=="RF"
			@ 0,0 VTSay Padr("Separe "+Alltrim(Str(nQtdSep,aTam[1],aTam[2]))+" "+cUnidade,20) // //"Separe "
		Else
			If Len(__aOldTela	) >= 4
				__aOldTela[4,2]:= Alltrim(Str(nQtdSep,aTam[1],aTam[2]))+" "+cUnidade
			EndIf
		EndIf
	EndIf
	VTSetKey(24,bKey24,cKey24)
Return(lRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ EstEnd   ³ Autor ³ ACD                   ³ Data ³ 14/02/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Estorno da Separacao da Expedicao                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD  UTILIZADO PARA CODIGO INTERNO E NATURAL           ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function EstEnd()
	Local aTela
	Local cEtiqEnd   := Space(20)
	Local cArmazem   := Space(Tamsx3("B1_LOCPAD")[1])
	Local cEndereco  := Space(TamSX3("BF_LOCALIZ")[1])
	Local cProduto   := Space(48)
	Local cIdVol     := Space(10)
	Local cSubVolume := Space(10)
	Local nQtde      := 1
	Local nOpc       := 1
	Local cKey21
	Local bKey21

	Private cLoteNew := Space(TamSX3("B8_LOTECTL")[1])
	Private cSLoteNew:= Space(TamSX3("B8_NUMLOTE")[1])
	Private lForcaQtd:= GetMV("MV_CBFCQTD",,"2") =="1"
	IF !Type("lVT100B") == "L"
		Private lVT100B := .F.
	EndIf


	If SuperGetMv("MV_LOCALIZ")=="S"
		VtClear()
		If VtModelo()=="RF" .or. lVT100B // GetMv("MV_RF4X20")
			@ 0,0 VTSAY "Estorno" //"Estorno"
			@ 1,0 VTSay "Selecione:" //"Selecione:"
			nOpc:=VTaChoice(3,0,4,VTMaxCol(),{"Por Produto","Por Endereco"}) //"Por Produto"###"Por Endereco"
		Else
			@ 0,0 VTSAY "Estorno selecione:" //"Estorno selecione:"
			nOpc:=VTaChoice(1,0,1,VTMaxCol(),{"Por Produto","Por Endereco"}) //"Por Produto"###"Por Endereco"
		EndIf
	EndIf
	cVolume := Space(10)
	aTela := VTSave()
	VTClear()
	@ 0,0 VtSay Padc("Estorno da leitura",VTMaxCol()) //"Estorno da leitura"
	If lVT100B // GetMv("MV_RF4X20")
		While .T.
			@ 0,0 VtSay Padc("Estorno da leitura",VTMaxCol()) //"Estorno da leitura"

			If "01" $ CB7->CB7_TIPEXP
				@ 0,0 VTSay "Leia o volume" //"Leia o volume"
				@ 1,0 VTGet cIdVol pict "@!" Valid VldVolEst(cIdVol,@cVolume)
			EndIf
			cProduto   := Space(48)

			cKey21  := VTDescKey(21)
			bKey21  := VTSetKey(21)

			If ! UsaCB0("01")
				@ 2,0 VTSay "Qtde " VtGet nQtde pict cPictQtdExp valid nQtde > 0 when (lForcaQtd .or. VtLastkey()==5) //"Qtde "
			EndIf
			@ 3,0 VTSay "Leia o produto" VTGet cProduto pict "@!" VALID VTLastkey() == 5 .or. VldEstEnd(cProduto,@nQtde,cArmazem,cEndereco,cVolume,nOpc) //"Leia o produto"
			//@ 7,0 VTGet cProduto pict "@!" VALID VTLastkey() == 5 .or. VldEstEnd(cProduto,@nQtde,cArmazem,cEndereco,cVolume,nOpc)
		EndDo
	Else //Não usa parametro MV_RF4X20
		If "01" $ CB7->CB7_TIPEXP
			If VTModelo()=="RF"
				@ 3,0 VTSay "Leia o volume" //"Leia o volume"
				@ 4,0 VTGet cIdVol pict "@!" Valid VldVolEst(cIdVol,@cVolume)
			Else
				@ 1,0 Vtclear to 1,VtMaxCol()
				@ 1,0 VTSay "Volume" VTGet cIdVol pict "@!" Valid VldVolEst(cIdVol,@cVolume) //"Volume"
				VtRead
				If VtLastKey() == 27
					VTRestore(,,,,aTela)
					Return .f.
				Endif
			EndIf
		EndIf
		cProduto   := Space(48)

		cKey21  := VTDescKey(21)
		bKey21  := VTSetKey(21)

		If VtModelo() =="RF"
			If ! UsaCB0("01")
				@ 5,0 VTSay "Qtde " VtGet nQtde pict cPictQtdExp valid nQtde > 0 when (lForcaQtd .or. VtLastkey()==5) //"Qtde "
			EndIf
			@ 6,0 VTSay "Leia o produto" //"Leia o produto"
			@ 7,0 VTGet cProduto pict "@!" VALID VTLastkey() == 5 .or. VldEstEnd(cProduto,@nQtde,cArmazem,cEndereco,cVolume,nOpc)
		Else
			VTClear()
			If ! UsaCB0("01")
				If VtModelo() =="MT44"
					@ 0,0 VTSay "Estorno Qtde " VtGet nQtde pict cPictQtdExp valid nQtde > 0 when (lForcaQtd .or. VtLastkey()==5) //"Estorno Qtde "
				Else // mt 16
					@ 0,0 VTSay "Est.Qtde " VtGet nQtde pict cPictQtdExp valid nQtde > 0 when (lForcaQtd .or. VtLastkey()==5) //"Est.Qtde "
				EndIf
			Else
				@ 0,0 VTSay "Estorno" //"Estorno"
			EndIf
			@ 1,0 VTSay "Produto" VTGet cProduto pict "@!" VALID VTLastkey() == 5 .or. VldEstEnd(cProduto,@nQtde,cArmazem,cEndereco,cVolume,) //"Produto"
		EndIf
		VTRead
	EndIf
	VTSetKey(21,bKey21,cKey21)
	If VtLastKey() == 27
		VTRestore(,,,,aTela)
		Return .f.
	Endif
	VTRestore(,,,,aTela)
Return .t.



/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ VldVolEst³ Autor ³ Anderson Rodrigues    ³ Data ³ 26/11/03 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Validacao do Volume no estorno do mesmo                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function VldVolEst(cIDVolume,cVolumeAux)
	Local aRet := CBRetEti(cIDVolume,"05")
	Local cVolume
	If VtLastkey()== 05
		Return .t.
	EndIf
	If Empty(cIDVolume)
		Return .f.
	EndIf

	If UsaCB0("05")
		aRet := CBRetEti(cIDVolume,"05")
		If Empty(aRet)
			VtAlert("Etiqueta de volume invalida","Aviso",.t.,4000,3) //"Etiqueta de volume invalida"###"Aviso"
			VtKeyboard(Chr(20))  // zera o get
			Return .f.
		EndIf
		cVolume := aRet[1]
	Else
		cVolume := 	cIDVolume
	EndIf

	CB6->(DBSetOrder(1))
	If ! CB6->(DbSeek(xFilial("CB6")+cVolume))
		VtAlert("Codigo de volume nao cadastrado","Aviso",.t.,4000,3) //"Codigo de volume nao cadastrado"###"Aviso"
		VtKeyboard(Chr(20))  // zera o get
		Return .f.
	EndIf
	CB9->(DBSetOrder(2))
	If ! CB9->(DbSeek(xFilial("CB9")+cOrdSep+cVolume))
		VtAlert("Volume pertence a outra ordem de separacao","Aviso",.t.,4000,3) //"Volume pertence a outra ordem de separacao"###"Aviso"
		VtKeyboard(Chr(20))  // zera o get
		Return .f.
	EndIf
	cVolumeAux := cVolume
Return .t.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³VldEstEnd ³ Autor ³ ACD                   ³ Data ³ 03/01/02 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³Expedicao                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³SIGAACD                                                     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function VldEstEnd(cEProduto,nQtde,cArmazem,cEndereco,cVolume,nOpc)
	Local cTipo
	Local aEtiqueta,aRet
	Local cLote 	:= Space(TamSX3("B8_LOTECTL")[1])
	Local cSLote 	:= Space(TamSX3("B8_NUMLOTE")[1])
	Local cNumSer 	:= Space(TamSX3("BF_NUMSERI")[1])
	Local nQE 		:=0
	Local nP
	Local cProduto
	Local nTQtde 	:= 0
	Local aItensPallet:= {}
	Local lIsPallet := .T.
	Local lExistCB8 := .F.
	Local lTemSerie := .T.
	Local nQtdCB9 	:= 0
	Local nRecnoCB9 := 0
	Local aCB9Recno := {}
	Local lACD166EST:= ExistBlock("ACD166EST")

	Private nQtdLida  := 0

	If Empty(cEProduto)
		Return .F.
	EndIf

	If !CBLoad128(@cEProduto)
		VtKeyboard(Chr(20))  // zera o get
		Return .F.
	EndIf

	aItensPallet := CBItPallet(cEProduto)
	If Empty(aItensPallet)
		aItensPallet:={cEProduto}
		lIsPallet := .f.
	EndIf

	DbSelectArea("CB8")
	CB8->(DbSetOrder(7))
	aCB9Recno :={}
	For nP:= 1 to Len(aItensPallet)
		cTipo := CbRetTipo(aItensPallet[nP])
		If cTipo == "01"
			cEtiqueta:= aItensPallet[nP]
			aEtiqueta:= CBRetEti(cEtiqueta,"01")
			If Empty(aEtiqueta)
				VtAlert("Etiqueta invalida","Aviso",.t.,4000,3) //"Etiqueta invalida"###"Aviso"
				VtKeyboard(Chr(20))  // zera o get
				Return .f.
			EndIf
			If ! lIsPallet
				If ! Empty(CB0->CB0_PALLET)
					VTALERT("Etiqueta invalida, Produto pertence a um Pallet","Aviso",.T.,4000,3) //"Etiqueta invalida, Produto pertence a um Pallet"###"Aviso"
					VtKeyboard(Chr(20))  // zera o get
					Return .f.
				EndIf
			EndIf
			If (cArmazem+cEndereco) # aEtiqueta[10]+aEtiqueta[9]
				VtAlert("Endereco diferente","Aviso",.t.,4000,3) //"Endereco diferente"###"Aviso"
				VtKeyboard(Chr(20))  // zera o get
				Return .F.
			EndIf
			CB9->(DbSetorder(1))
			If ! CB9->(DbSeek(xFilial("CB9")+cOrdSep+Left(aItensPallet[nP],10))) //
				VtAlert("Produto nao separado","Aviso",.t.,4000,3) //"Produto nao separado"###"Aviso"
				VtKeyboard(Chr(20))  // zera o get
				Return .F.
			EndIf
		ElseIf cTipo $ "EAN8OU13-EAN14-EAN128"
			aRet := CBRetEtiEan(aItensPallet[nP])
			If Empty(aRet)
				VtAlert("Etiqueta invalida","Aviso",.t.,4000,3) //"Etiqueta invalida"###"Aviso"
				VtKeyboard(Chr(20))  // zera o get
				Return .F.
			EndIf
			cProduto := aRet[1]
			If cTipo $ "EAN8OU13"
				nQE  :=aRet[2] * nQtde
			Else
				nQE  :=aRet[2] * CBQtdEmb(aItensPallet[nP])*nQtde
			EndIf
			If Empty(nQE)
				VtAlert("Quantidade invalida","Aviso",.t.,4000,3) //"Quantidade invalida"###"Aviso"
				VtKeyboard(Chr(20))  // zera o get
				Return .F.
			EndIf
			cLote := aRet[3]
			If ! CBRastro(aRet[1],@cLote,@cSLote)
				VTKeyBoard(chr(20))
				Return .f.
			EndIf
			If Empty(cEndereco) .And. Localiza(cProduto)
				A166GetEnd(@cArmazem,@cEndereco)
			EndIf
			If ! Empty(aRet[5])
				cNumSer := aRet[5]
			Else
				// pedir  o numero de serie se tiver
				// descobrir se o produto tem numero de serie
				lTemSerie := .f.
				CB8->(DbSetOrder(7))
				CB8->(DbSeek(xFilial("CB8")+cOrdSep+cArmazem))
				While CB8->(!Eof() .AND. CB8_FILIAL+CB8_ORDSEP+CB8_LOCAL== xFilial("CB8")+cOrdSep+cArmazem)
					// no cb8 não tem volume portanto nao sendo necessario analisar o volume
					If ! CB8->(CB8_PROD+CB8_LOTECT+CB8_NUMLOT)==cProduto+cLote+cSLote
						CB8->(DbSkip())
						Loop
					EndIf
					If ! Empty(CB8->CB8_NUMSER)
						lTemSerie := .t.
						Exit
					EndIf
					CB8->(DbSkip())
				EndDo
				If lTemSerie
					If ! CBNumSer(@cNumSer,,,.T.)
						VTKeyBoard(chr(20))
						Return .f.
					EndIf
				EndIf
			EndIf

			If lACD166EST
				aRet := ExecBlock("ACD166EST",.F.,.F.,{aRet,cArmazem,cEndereco})
				If Empty(aRet) .Or. ValType(aRet)<> "A"
					VTKeyBoard(chr(20))
					Return .f.
				EndIf
				cProduto:= aRet[1]
				cLote 	:= aRet[3]
				cNumSer	:= aRet[5]
			EndIf

			If Empty(CB7->CB7_PRESEP) // convencional
				//Verifica se existe no CB8 se existem itens quantidades separadas para o produto informado
				CB8->(DbSetOrder(7))
				CB8->(DbSeek(xFilial("CB8")+cOrdSep+cArmazem+cEndereco+cProduto+cLote+cSLote+cNumSer))
				While CB8->(!Eof() .AND. CB8_FILIAL+CB8_ORDSEP+CB8_LOCAL+CB8_LCALIZ+CB8_PROD+CB8_LOTECT+CB8_NUMLOT+CB8_NUMSER== ;
						xFilial("CB8")+cOrdSep+cArmazem+cEndereco+cProduto+cLote+cSLote+cNumSer)
					If CB8->(CB8_QTDORI > CB8_SALDOS)
						lExistCB8 := .t.
						Exit
					EndIf
					CB8->(DbSkip())
				EndDo
				If !lExistCB8
					VtAlert("Item nao encontrado","Aviso",.t.,4000,3) //"Item nao encontrado"###"Aviso"
					VtKeyboard(Chr(20))  // zera o get
					Return .F.
				EndIf

				cLoteNew  := cLote
				cSLoteNew := cSLote

				nTQtde := 0
				CB9->(DbSetorder(8))
				If !CB9->(DBSeek(xFilial("CB9")+cOrdSep+cProduto+cLoteNew+cSLoteNew+cNumSer+cVolume+CB8->CB8_ITEM+cArmazem+cEndereco))
					VtAlert("Volume ou etiqueta invalida","Aviso",.t.,4000,3) //"Volume ou etiqueta invalida"###"Aviso"
					VtKeyboard(Chr(20))  // zera o get
					Return .f.
				EndIf
				If nQE > CB9->CB9_QTESEP
					VtAlert("Quantidade informada maior do que separada","Aviso",.t.,4000,3) //"Quantidade informada maior do que separada"###"Aviso"
					VtKeyboard(Chr(20))  // zera o get
					Return .F.
				EndIf
			Else // quando a origem for uma pre-separacao
				//Verifica se existe no CB8 se existem itens quantidades separadas para o produto informado
				CB8->(DbSetOrder(7))
				CB8->(DbSeek(xFilial("CB8")+cOrdSep+cArmazem))
				While CB8->(!Eof() .AND. CB8_FILIAL+CB8_ORDSEP+CB8_LOCAL== xFilial("CB8")+cOrdSep+cArmazem)
					// no cb8 não tem volume portanto nao sendo necessario analisar o volume
					If ! CB8->(CB8_PROD+CB8_LOTECT+CB8_NUMLOT+CB8_NUMSER)==cProduto+cLote+cSLote+cNumSer
						CB8->(DbSkip())
						Loop
					EndIf
					If CB8->(CB8_QTDORI > CB8_SALDOS)
						lExistCB8 := .t.
						Exit
					EndIf
					CB8->(DbSkip())
				EndDo
				If !lExistCB8
					VtAlert("Item nao encontrado","Aviso",.t.,4000,3) //"Item nao encontrado"###"Aviso"
					VtKeyboard(Chr(20))  // zera o get
					Return .F.
				EndIf
				cLoteNew  := cLote
				cSLoteNew := cSLote

				nTQtde := 0
				CB9->(DbSetorder(10))
				If ! CB9->(DbSeek(xFilial("CB9")+cOrdSep))
					VtAlert("Volume ou etiqueta invalida","Aviso",.t.,4000,3) //"Volume ou etiqueta invalida"###"Aviso"
					VtKeyboard(Chr(20))  // zera o get
					Return .f.
				EndIf
				nQtdCB9:=0
				While CB9->(! Eof() .and. CB9_FILIAL+CB9_ORDSEP == xFilial("CB9")+cOrdSep)
					If CB9->(CB9_LOCAL+CB9_PROD+CB9_LOTECT+CB9_NUMLOT+CB9_NUMSER+CB9_VOLUME) == cArmazem+cProduto+cLoteNew+cSLoteNew+cNumSer+cVolume
						If Empty(nRecnoCB9)
							nRecnoCB9 := CB9->(Recno())
						EndIf
						nQtdCB9+=CB9->CB9_QTESEP
					EndIf
					CB9->(DbSkip())
				EndDo
				CB9->(DbGoto(nRecnoCB9)) // necessario posicionar no primeiro valido para a rotina   GrvEstCB9(...)
				If Empty(nQtdCB9)
					VtAlert("Volume ou etiqueta invalida","Aviso",.t.,4000,3) //"Volume ou etiqueta invalida"###"Aviso"
					VtKeyboard(Chr(20))  // zera o get
					Return .f.
				EndIf
				If nQE > nQtdCB9
					VtAlert("Quantidade informada maior do que separada","Aviso",.t.,4000,3) //"Quantidade informada maior do que separada"###"Aviso"
					VtKeyboard(Chr(20))  // zera o get
					Return .F.
				EndIf
			EndIf
		Else
			VtAlert("Etiqueta invalida","Aviso",.t.,4000,3) //"Etiqueta invalida"###"Aviso"
			VtKeyboard(Chr(20))  // zera o get
			Return .F.
		EndIf
		AADD(aCB9Recno,CB9->(Recno()))
	Next
	If ! VtYesNo("Confirma o estorno?","Aviso",.t.)  //"Confirma o estorno?"###"Aviso"
		VtKeyboard(Chr(20))  // zera o get
		Return .F.
	EndIf


	For nP:= 1 to Len(aItensPallet)
		If UsaCB0("01")
			cTipo := CbRetTipo(aItensPallet[nP])
			If cTipo # "01"
				Loop
			Endif
			cEtiqueta:= aItensPallet[nP]
			aEtiqueta:= CBRetEti(cEtiqueta,"01")
			cProduto := aEtiqueta[1]
			nQE      := aEtiqueta[2]
			cLote    := aEtiqueta[16]
			cSLote   := aEtiqueta[17]
			nQtdLida := nQE
			CB9->(DbSetorder(1))
			If !CB9->(DbSeek(xFilial("CB9")+cOrdSep+Left(aItensPallet[nP],10)))
				Loop
			EndIf
			GrvEstCB9(nQtdLida)

		Else
			CB9->(DbGoto(aCB9Recno[nP]))
			nQtdLida := nQE
			GrvEstCB9(nQtdLida)
		EndIf
	Next nP
	nQtde:= 1
	VTGetRefresh("nQtde") //
	VtKeyboard(Chr(20))  // zera o get
	If !UsaCB0("01") .and. lForcaQtd
		A166MtaEst(nQtde,cArmazem,cEndereco,cVolume,nOpc)
		Return
	Else
		Return .F.
	EndIf

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ EstProd  ³ Autor ³ ACD                   ³ Data ³ 15/02/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Expedicao                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD SOMENTE COM CODIGO INTERNO                         ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function EstProd()
	Local aTela	    := VTSave()
	Local cEtiqEnd  := Space(20)
	Local cArmazem  := Space(Tamsx3("B1_LOCPAD")[1])
	Local cEndereco := Space(TamSX3("BF_LOCALIZ")[1])
	Local cArm2     := Space(Tamsx3("B1_LOCPAD")[1])
	Local cEnd2     := Space(15)
	Local cProduto  := Space(48)
	Local cIdVol    := Space(10)
	Local cSubVolume:= Space(10)
	Local cEtiqueta := Space(20)
	Local cLote     := Space(TamSX3("B8_LOTECTL")[1])
	Local cSLote    := Space(TamSX3("B8_NUMLOTE")[1])
	Local nQtde     := 1
	Local nP		:= 0
	Local nQE	    := 0
	Local nTamEti1  := TamSx3("CB0_CODETI")[1]
	Local nTamEti2  := TamSx3("CB0_CODET2")[1]-1
	Local cEtiAux   := ""
	Local lCONFEND 	:= GETMV("MV_CONFEND") # "1"

	Private nQtdLida := 0
	Private aItensPallet:= {}
	Private cLoteNew := Space(TamSX3("B8_LOTECTL")[1])
	Private cSLoteNew:= Space(TamSX3("B8_NUMLOTE")[1])
	IF !Type("lVT100B") == "L"
		Private lVT100B := .F.
	EndIf


	While .t.
		cVolume    := Space(10)

		VTClear()
		@ 0,0 VtSay Padc("Estorno da leitura",VTMaxCol()) //"Estorno da leitura"
		If "01" $ CB7->CB7_TIPEXP
			@ 1,0 VTSay "Leia o volume" //"Leia o volume"
			@ 2,0 VTGet cIdVol pict "@!" Valid VldVolEst(cIdVol,@cVolume)
		EndIf
		cProduto   := Space(48)
		If ! UsaCB0("01")
			@ 3,0 VTSay "Qtde " VtGet nQtde pict cPictQtdExp valid nQtde > 0 when VtLastkey()==5 //"Qtde "
		EndIf
		@ 4,0 VTSay "Leia o produto" //"Leia o produto"
		@ 5,0 VTGet cProduto pict "@!" VALID VTLastkey() == 5 .or. VldEstProd(cProduto,@nQtde,@cArmazem,@cEndereco,cVolume)
		VTRead()
		If VtLastKey() == 27
			VTRestore(,,,,aTela)
			Return .f.
		Endif
		VtClear()
		If Empty(cArm2+cEnd2) .or. (cArm2+cEnd2 # cArmazem+cEndereco)
			@ 0,0 VTSay "Va para o endereco" //"Va para o endereco"
			@ 1,0 VTSay cArmazem+"-"+cEndereco
			cArm2   := cArmazem
			cEnd2   := cEndereco
			cEtiqEnd:= Space(20)
			If lCONFEND
				@ 4,0 VTPause "Enter para continuar" //"Enter para continuar"
			Endif
		Endif
		If VtLastKey() == 27
			VTRestore(,,,,aTela)
			Return .f.
		Endif
		If ! VtYesNo("Confirma o estorno?","Aviso",.t.) //"Confirma o estorno?"###"Aviso"
			Loop
		EndIf
		For nP:= 1 to Len(aItensPallet)
			cEtiqueta:= aItensPallet[nP]
			aEtiqueta:= CBRetEti(cEtiqueta,"01")
			cProduto := aEtiqueta[1]
			nQE      := aEtiqueta[2]
			cLote    := aEtiqueta[16]
			cSLote   := aEtiqueta[17]

			// Verifica se valida pelo codigo interno ou de cliente
			If Len(Alltrim(aItensPallet[nP])) <=  nTamEti1 // Codigo Interno
				cEtiAux := Left(aItensPallet[nP],nTamEti1)
			ElseIf Len(Alltrim(aItensPallet[nP])) ==  nTamEti2 // Codigo Cliente
				cEtiAux := A166RetEti(Left(aItensPallet[nP],nTamEti2))
			EndIf

			CB9->(DbSetorder(1))
			If CB9->(DbSeek(xFilial("CB9")+cOrdSep+cEtiAux))
				GrvEstCB9(nQE)
			EndIf
		Next
		If VtLastKey() == 27
			Exit
		Endif
	Enddo
	VTRestore(,,,,aTela)
Return .t.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³VldEstProd³ Autor ³ ACD                   ³ Data ³ 03/01/02 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³Validacao da etiqueta para fazer estorno / devolucao        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function VldEstProd(cEProduto,nQtde,cArmazem,cEndereco,cVolume)
	Local  aEtiqueta
	Local  nP
	Local  lIsPallet:= .T.
	Local nTamEti1   := TamSx3("CB0_CODETI")[1]
	Local nTamEti2   := TamSx3("CB0_CODET2")[1]-1
	Local cEtiAux    := ""
	Private nQtdLida :=0

	If Empty(cEProduto)
		Return .f.
	EndIf

	aItensPallet := CBItPallet(cEProduto)
	If Len(aItensPallet) == 0
		aItensPallet:={cEProduto}
		lIsPallet := .f.
	EndIf

	For nP:= 1 to Len(aItensPallet)
		cEtiqueta:= aItensPallet[nP]
		aEtiqueta:= CBRetEti(cEtiqueta,"01")
		If Empty(aEtiqueta)
			VtAlert("Etiqueta invalida","Aviso",.t.,4000,3) //"Etiqueta invalida"###"Aviso"
			VtKeyboard(Chr(20))  // zera o get
			Return .f.
		EndIf
		If ! lIsPallet
			If ! Empty(CB0->CB0_PALLET)
				VTALERT("Etiqueta invalida, Produto pertence a um Pallet","Aviso",.T.,4000,3) //"Etiqueta invalida, Produto pertence a um Pallet"###"Aviso"
				VtKeyboard(Chr(20))  // zera o get
				Return .f.
			Endif
		Endif

		// Verifica se valida pelo codigo interno ou de cliente
		If Len(Alltrim(aItensPallet[nP])) <=  nTamEti1 // Codigo Interno
			cEtiAux := Left(aItensPallet[nP],nTamEti1)
		ElseIf Len(Alltrim(aItensPallet[nP])) ==  nTamEti2 // Codigo Cliente
			cEtiAux := A166RetEti(Left(aItensPallet[nP],nTamEti2))
		EndIf

		CB9->(DbSetorder(1))
		If ! CB9->(DbSeek(xFilial("CB9")+cOrdSep+cEtiAux))
			VtAlert("Produto nao separado","Aviso",.t.,4000,3) //"Produto nao separado"###"Aviso"
			VtKeyboard(Chr(20))  // zera o get
			Return .F.
		EndIf
	Next
	cArmazem := CB0->CB0_LOCAL
	cEndereco:= CB0->CB0_LOCALI
Return .t.

Static Function MSCBFSem()
	Local nC:= 0
	__nSem := -1
	While __nSem  < 0
		__nSem  := MSFCreate("V166"+cOrdSep+"TESTE")
		IF  __nSem  < 0
			SLeep(50)
			nC++
			If nC == 3
				Return .f.
			EndIf
		EndIf
	EndDo
	FWrite(__nSem,"Operador: "+cCodOpe+" Ordem de Separacao: "+cOrdSep) //"Operador: "###" Ordem de Separacao: "
Return .t.

Static Function MSCBASem()
	If __nSem > 0
		Fclose(__nSem)
		FErase("V166"+cOrdSep+"TESTE")
	EndIf
Return 10

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ExistCB9Sp³ Autor ³ ACD                   ³ Data ³ 15/02/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Verifica se existe algum produto ja separado para a ordem  ³±±
±±³          ³ de separacao informada.                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametro ³ cOrdSep : codigo da ordem de separacao a ser analisada.    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Logico                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function ExistCB9Sp(cOrdSep)
	CB9->(DBSetOrder(1))
	CB9->(DbSeek(xFilial("CB9")+cOrdSep))
	While CB9->(! Eof() .and. CB9_FILIAL+CB9_ORDSEP == xFilial("CB9")+cOrdSep)
		If ! Empty(CB9->CB9_QTESEP)
			Return .T.
		EndIf
		CB9->(DbSkip())
	Enddo
Return .F.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ EstItemPv ³ Autor ³ ACD                 ³ Data ³ 23/02/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Estorna itens do Pedido de Vendas                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function EstItemPv()
	Local  aSvAlias     := GetArea()
	Local  aSvCB8       := CB8->(GetArea())
	Local  aSvSC6       := SC6->(GetArea())
	Local  aSvSB7       := SB7->(GetArea())
	Local  aItensDiverg := {}
	Local  nPos, i
	Local  cPRESEP := CB7->CB7_PRESEP

// Verifica se a Ordem de separacao possui pre-separacao se possuir verificar se existe divergencia
// excluindo o item do pedido de venda.
	If !Empty(CB7->CB7_PRESEP)
		CB7->(DbSetOrder(1))
		If CB7->(DbSeek(xFilial("CB7")+cPRESEP))
			If CB7->CB7_DIVERG # "1"
				RestArea(aSvSB7)
			EndIf
			cOrdSep := cPRESEP
		EndIf
	EndIf

	CB8->(DbSetOrder(1))
	CB8->(DbSeek(xFilial("CB8")+CB7->CB7_ORDSEP))

	If CB8->CB8_CFLOTE <> "1"
		v166TcLote (CB7->CB7_ORDSEP)
	EndIf

	If CB7->CB7_ORIGEM # "1" .or. CB7->CB7_DIVERG # "1"
		Return
	EndIf

	CB8->(DbSetOrder(1))
	CB8->(DbSeek(xFilial("CB8")+CB7->CB7_ORDSEP))
	While CB8->(!Eof() .and. CB8_ORDSEP == CB7->CB7_ORDSEP)
		If ! AllTrim(CB8->CB8_OCOSEP) $ cDivItemPv
			CB8->(DbSkip())
			Loop
		EndIf
		If (Ascan(aItensDiverg,{|x| x[1]+x[2]+x[3]+x[6]+x[7]+x[8]== ;
				CB8->(CB8_PEDIDO+CB8_ITEM+CB8_PROD+CB8_LOCAL+CB8_LCALIZ+CB8_SEQUEN)})) == 0
			aAdd(aItensDiverg,{CB8->CB8_PEDIDO,CB8->CB8_ITEM,CB8->CB8_PROD,If(CB8->(CB8_QTDORI-CB8_SALDOS)==0,CB8->CB8_QTDORI,CB8->(CB8_QTDORI-CB8_SALDOS)),CB8->(Recno()),CB8->CB8_LOCAL,CB8->CB8_LCALIZ,CB8->CB8_SEQUEN})
		EndIf
		CB8->(DbSkip())
	EndDo
	If Empty(aItensDiverg)
		RestArea(aSvSC6)
		RestArea(aSvCB8)
		RestArea(aSvAlias)
		Return
	EndIf

	Libera(aItensDiverg)  //Estorna a liberacao de credito/estoque dos itens divergentes ja liberados

// ---- Exclusao dos itens da Ordem de Separacao com divergencia (MV_DIVERPV):
	For i:=1 to len(aItensDiverg)
		CB8->(DbGoto(aItensDiverg[i][5]))
		RecLock("CB8")
		CB8->(DbDelete())
		CB8->(MsUnlock())

		// ---- Exclusao dos itens separados com divergencias
		CB9->(DbSetOrder(9))
		CB9->(DbSeek(xFilial("CB9")+CB8->(CB8_ORDSEP+CB8_PROD+CB8_LOCAL)))
		While CB9->(! Eof() .and. CB9_FILIAL+CB9_ORDSEP+CB9_PROD+CB9_LOCAL == xFilial("CB9")+CB8->(CB8_ORDSEP+CB8_PROD+CB8_LOCAL))
			If CB9->(CB9_ITESEP+CB9_SEQUEN) == CB8->(CB8_ITEM+CB8_SEQUEN)
				RecLock("CB9")
				CB9->(DbDelete())
				CB9->(MsUnlock())
				CB9->(DbSkip())
			Else
				CB9->(DbSkip())
			EndIf
		EndDo
	Next i

// ---- Alteracao do CB7:
	RecLock("CB7")
	CB7->CB7_DIVERG := ""
	CB7->(MsUnlock())

	RestArea(aSvSB7)
	RestArea(aSvSC6)
	RestArea(aSvCB8)
	RestArea(aSvAlias)
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ Libera   ³ Autor ³ ACD                   ³ Data ³ 03/01/02 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Faz a liberacao do Pedido de Venda para a geracao da NF    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function Libera(aItensDiverg)
	Local nX,ny,nz
	Local nQtdLib   := 0
	Local lContinua := .f.
	Local aPedidos  := {}
	Local aEmp      := {}
	Local aCB8      := CB8->( GetArea() )
	Local lACD166FLIB := .F.
	Local l166FLIB 	:= ExistBlock("ACD166FLIB")
	Local nPosDiv

	Default aItensDiverg := {}

	CB8->(DbSetOrder(1))
	CB8->(DbSeek(xFilial("CB8")+cOrdSep))
	While  CB8->(! Eof() .AND. CB8_FILIAL+CB8_ORDSEP==xFilial("CB8")+cOrdSep)
		If Ascan(aPedidos,{|x| x[1]+x[2]== CB8->(CB8_PEDIDO+CB8_ITEM)}) == 0
			aAdd(aPedidos,{CB8->CB8_PEDIDO,CB8->CB8_ITEM})
		EndIf
		CB8->(DbSkip())
		Loop
	EndDo

	aPvlNfs  :={}
	For nX:= 1 to len(aPedidos)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Libera quantidade embarcada³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		SC5->(dbSetOrder(1))
		SC5->(DbSeek(xFilial("SC5")+aPedidos[nx,1]))
		SC6->(DbSetOrder(1))
		SC6->(DbSeek(xFilial("SC6")+aPedidos[nx,1]+aPedidos[nx,2]))
		SC9->(DbSetOrder(1))
		If !SC9->(DbSeek(xFilial("SC9")+SC6->C6_NUM+aPedidos[nx,2]))
			While SC6->(!Eof() .and. C6_FILIAL+C6_NUM+C6_ITEM==xFilial("SC6")+aPedidos[nX,1]+aPedidos[nx,2])
				aEmp := LoadEmpEst()
				nQtdLib := SC6->C6_QTDVEN
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ LIBERA (Pode fazer a liberacao novamente caso com novos lotes³
				//³         caso possua)                                         ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				MaLibDoFat(SC6->(Recno()),nQtdLib,.T.,.T.,.F.,.F.,	.F.,.F.,	NIL,{||SC9->C9_ORDSEP := cOrdSep},aEmp,.T.)
				SC6->(DbSkip())
			EndDo
			Loop
		EndIf

		ny:= nx
		While SC6->(!Eof() .and. C6_FILIAL+C6_NUM+C6_ITEM==xFilial("SC6")+aPedidos[ny,1]+aPedidos[ny,2])
			If !Empty(aItensDiverg)
				If Empty(Ascan(aItensDiverg,{|x| x[1]+x[2]+x[3]== SC6->(C6_NUM+C6_ITEM+C6_PRODUTO)}))
					SC6->(DbSkip())
					Loop
					ny ++
				EndIf
			EndIf
			nQtdLib   := SC6->C6_QTDVEN
			lContinua := .f.
			While SC9->(! Eof() .and. C9_FILIAL+C9_PEDIDO+C9_ITEM==xFilial("SC9")+SC6->(C6_NUM+C6_ITEM))
				If Empty(SC9->C9_NFISCAL) .and. SC9->C9_AGREG == CB7->CB7_AGREG
					lContinua:= .t.
					Exit
				EndIf
				SC9->(DbSkip())
			EndDo
			If ! lContinua
				SC6->(DbSkip())
				Loop
			EndIf

			If l166FLIB
				// Ponto de entrada para forcar a liberacao de pedidos:
				lACD166FLIB := ExecBlock("ACD166FLIB",.F.,.F.)
				lACD166FLIB := (If(ValType(lACD166FLIB) == "L",lACD166FLIB,.F.))
			Endif

			//Esta validacao sera verdadeira se o produto tiver rastro e nao houver verficacao no momento da leitura
			//sendo assim sendo necessario estonar o SDC e gera outro conforme os itens lidos pelo coletor.
			//ou se o item do pedido estiver marcado com divergencia da leitura o mesmo devera ser estornado e sera
			//necessario liberar novamente sem o vinculo da ordem de separacao.
			If (RASTRO(SC6->C6_PRODUTO) .AND. CB8->CB8_CFLOTE <> "1" ) .or. !Empty(aItensDiverg) .or. lACD166FLIB
				aEmp := LoadEmpEst()
				nPosDiv := Ascan(aItensDiverg,{|x| x[1]+x[2]+x[3]== SC6->(C6_NUM+C6_ITEM+C6_PRODUTO)})
				If nPosDiv <> 0
					A166AvalLb(aEmp,aItensDiverg[nPosDiv])
				End if
			EndIf

			SC9->(DbSetOrder(1))
			SC9->(DbSeek(xFilial("SC9")+SC6->(C6_NUM+C6_ITEM)))               //FILIAL+NUMERO+ITEM
			While SC9->(! Eof() .and. C9_FILIAL+C9_PEDIDO+C9_ITEM==xFilial("SC9")+SC6->(C6_NUM+C6_ITEM))
				If ! Empty(SC9->C9_NFISCAL) .or. SC9->C9_AGREG # CB7->CB7_AGREG .or. SC9->C9_ORDSEP # CB7->CB7_ORDSEP
					SC9->(DbSkip())
					Loop
				EndIf
				SE4->(DbSetOrder(1))
				SE4->(DbSeek(xFilial("SE4")+SC5->C5_CONDPAG))
				SB1->(DbSetOrder(1))
				SB1->(DbSeek(xFilial("SB1")+SC6->C6_PRODUTO))              //FILIAL+PRODUTO
				SB2->(DbSetOrder(1))
				SB2->(DbSeek(xFilial("SB2")+SC6->(C6_PRODUTO+C6_LOCAL)))  //FILIAL+PRODUTO+LOCAL
				SF4->(DbSetOrder(1))
				SF4->(DbSeek(xFilial("SF4")+SC6->C6_TES) )                 //FILIAL+CODIGO
				SC9->(aadd(aPvlNfs,{C9_PEDIDO,;
					C9_ITEM,;
					C9_SEQUEN,;
					C9_QTDLIB,;
					C9_PRCVEN,;
					C9_PRODUTO,;
					(SF4->F4_ISS=="S"),;
					SC9->(RecNo()),;
					SC5->(RecNo()),;
					SC6->(RecNo()),;
					SE4->(RecNo()),;
					SB1->(RecNo()),;
					SB2->(RecNo()),;
					SF4->(RecNo())}))
				SC9->(DbSkip())
			EndDo
			SC6->(DbSkip())
		Enddo
	Next

	CB8->(RestArea(aCB8))
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ LoadEmpEst      ³ Autor ³ ACD            ³ Data ³ 21/03/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Reajusta o empenho dos produtos separados caso necessario  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function LoadEmpEst(lLotSug,lTroca)
	Local aEmp:={}
	Local aEtiqueta:={}
	Default lLotSug := .T.
	Default lTroca  := .F.

	CB9->(DBSetOrder(11))
	CB9->(DbSeek(xFilial("CB9")+CB7->CB7_ORDSEP+SC6->C6_ITEM+SC6->C6_NUM))
	While CB9->(! Eof() .and. CB9_FILIAL+CB9_ORDSEP+CB9_ITESEP+CB9_PEDIDO == xFilial("CB9")+CB7->CB7_ORDSEP+SC6->C6_ITEM+SC6->C6_NUM)
		If !lLotSug .And. lTroca
			nPos :=ascan(aEmp,{|x| x[1]+x[2]+x[3]+x[4]+x[11] == CB9->(CB9_LOTECT+CB9_NUMLOT+CB9_LCALIZ+CB9_NSERSU+CB9_LOCAL)})
			If !CB9->(a166VldSC9(1,CB9_PEDIDO+CB9_ITESEP+CB9_SEQUEN+CB9_PROD))
				If Empty(nPos)
					CB9->(aadd(aEmp,{CB9_LOTECT, ;								                  // 1
					CB9_NUMLOT,;								                  // 2
					CB9_LCALIZ, ;								                  // 3
					CB9_NSERSU,;                                             // 4
					CB9_QTESEP,;								                  // 5
					ConvUM(CB9_PROD,CB9_QTESEP,0,2),;                        // 6
					a166DtVld(CB9_PROD,CB9_LOCAL,CB9_LOTECT, CB9_NUMLOT),;  // 7
					,;                 						                  // 8
					,;									                         // 9
					,;									                         // 10
					CB9_LOCAL,;								                  // 11
					0}))								                         // 12
				Else
					aEmp[nPos,5] +=CB9->CB9_QTESEP
				EndIf
			EndIf
		ElseIf !lLotSug
			nPos :=ascan(aEmp,{|x| x[1]+x[2]+x[3]+x[4]+x[11] == CB9->(CB9_LOTECT+CB9_NUMLOT+CB9_LCALIZ+CB9_NSERSU+CB9_LOCAL)})
			If Empty(nPos)
				CB9->(aadd(aEmp,{CB9_LOTECT, ;								                  // 1
				CB9_NUMLOT,;								                  // 2
				CB9_LCALIZ, ;								                  // 3
				CB9_NSERSU,;                                             // 4
				CB9_QTESEP,;								                  // 5
				ConvUM(CB9_PROD,CB9_QTESEP,0,2),;                        // 6
				a166DtVld(CB9_PROD,CB9_LOCAL,CB9_LOTECT, CB9_NUMLOT),;  // 7
				,;                 						                  // 8
				,;									                         // 9
				,;									                         // 10
				CB9_LOCAL,;								                  // 11
				0}))								                         // 12
			Else
				aEmp[nPos,5] +=CB9->CB9_QTESEP
			EndIf
		Else
			nPos :=ascan(aEmp,{|x| x[1]+x[2]+x[3]+x[4]+x[11] == CB9->(CB9_LOTSUG+CB9_SLOTSUG+CB9_LCALIZ+CB9_NSERSU+CB9_LOCAL)})
			If Empty(nPos)
				CB9->(aadd(aEmp,{CB9_LOTSUG,;								                  // 1
				CB9_SLOTSUG,;								                  // 2
				CB9_LCALIZ,;								                  // 3
				CB9_NSERSU,;                                             // 4
				CB9_QTESEP,;								                  // 5
				ConvUM(CB9_PROD,CB9_QTESEP,0,2),;                        // 6
				a166DtVld(CB9_PROD,CB9_LOCAL,CB9_LOTECT, CB9_NUMLOT),;  // 7
				,;                                                       // 8
				,;                                                       // 9
				,;                                                       // 10
				CB9_LOCAL,;								                  // 11
				0}))								                         // 12
			Else
				aEmp[nPos,5] +=CB9->CB9_QTESEP
			EndIf
		EndIf
		If ! Empty(CB9->CB9_CODETI)
			aEtiqueta := CBRetEti(CB9->CB9_CODETI,"01")
			If ! Empty(aEtiqueta)
				aEtiqueta[13]:= CB7->CB7_NOTA
				aEtiqueta[14]:= CB7->CB7_SERIE
				CBGrvEti("01",aEtiqueta,CB9->CB9_CODETI)
			EndIf
		EndIf
		CB9->(DBSkip())
	EndDo
Return aEmp

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³ RequisitOP ³ Autor ³ ACD                 ³ Data ³ 03/01/02 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Executa rotina automatica de requisicao - MATA240          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SIGAACD                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function RequisitOP(lEstorno,lApp)
	Local aMata     := {}
	Local aEmp      := {}
	Local dValid    := ctod('')
	Local nModuloOld:= nModulo
	Local aCab      := {}
	Local aCB8      := CB8->(GetArea())
	Local aSD3      := SD3->(GetArea())
	Local cTRT      := ""
	Local n1        := 0
	Local aRetPESD3 := {}
	Local lEstReq   := .F.
	Local lACD166RQ := ExistBlock("ACD166RQ")

	Private nModulo  := 4
	Private cTM      := GETMV("MV_CBREQD3")
	Private cDistAut := GETMV("MV_DISTAUT")

	Default lEstorno := .F.
	Default lApp	 := .F.
/*
SANDRO E ERIKE:

- Criei um campo para controle do N.Docto na separacao: CB9_DOC cujo contira o documento D3_DOC.
  O mesmo deverah ser criado no ATUSX, certo!

BY ERIKE : O campo ja foi criado no ATUSX
*/
	If !lApp
		If ! lEstorno
			If ! VTYesNo("Confirma a requisicao dos itens?","Aviso",.t.) //"Confirma a requisicao dos itens?"###"Aviso"
				Return .f.
			EndIf
		Else
			If ! VTYesNo("Confirma o estorno da requisicao dos itens?","Aviso",.t.) //"Confirma o estorno da requisicao dos itens?"###"Aviso"
				Return .f.
			EndIf
		EndIf
		VTMSG("Processando") //"Processando"
	EndIf

	aEmp := A166AvalEm(lEstorno)

	Begin Transaction
		SB1->(DbSetOrder(1))
		CB8->(DbSetOrder(4))
		CB9->(DBSetOrder(1))
		CB9->(DbSeek(xFilial("CB9")+CB7->CB7_ORDSEP))
		While CB9->(! Eof() .And. xFilial("CB9")+CB7->CB7_ORDSEP == CB9_FILIAL+CB9_ORDSEP)
			If	If(lEstorno,!Empty(CB9->CB9_DOC),Empty(CB9->CB9_DOC))
				If	(n1 := aScan(aEmp,{|x| x[1]+x[2]+x[3]+x[4]+x[5]==CB9->(CB9_PROD+CB9_LOCAL+CB9_LCALIZ+CB9_LOTSUG+CB9_SLOTSU)}))>0
					If lEstorno .AND. CBArmProc(CB9->CB9_PROD,cTM) .AND. !Empty(cDistAut)
						//Usuario deve estornar o enderecamento do Armazem de Processo (MV_DISTAUT), atraves do Protheus
						//para posteriormente estornar a requisicao e a separacao atraves desta rotina
						lEstReq := .T.
						If !lApp
							VTBeep(2)
							VTAlert("Existem produtos enderecados para o Armazem de processo!","Aviso",.T.,6000)//"Existem produtos enderecados para o Armazem de processo!","Aviso"
						EndIf
						DisarmTransaction()
						Break
					Endif
					cTRT := aEmp[n1,7]
					CB8->(DbSeek(xFilial("CB8")+CB9->(CB9_ORDSEP+CB9_ITESEP+CB9_PROD+CB9_LOCAL+CB9_LCALIZ+CB9_LOTSUG+CB9_SLOTSU+CB9_NUMSER)))
					SB1->(DbSeek(xFilial("SB1")+CB9->CB9_PROD))
					RecLock("CB9",.F.)
					CB9->CB9_DOC := If(lEstorno,Space(TamSx3("CB9_DOC")[1]),SD3->D3_DOC)
					CB9->(MsUnlock())
				EndIf
			EndIf
			CB9->(DbSkip())
		EndDo
		nModulo := nModuloOld
		CB7->(RecLock("CB7"))
		If	lEstorno
			CB7->CB7_REQOP := "0"
		Else
			CB7->CB7_REQOP := "1"
		EndIf
		CB7->(MsUnlock())
	End Transaction
	If	lMSErroAuto
		VTDispFile(NomeAutoLog(),.t.)
	EndIf

	CB8->(RestArea(aCB8))
	SD3->(RestArea(aSD3))
Return !lMSErroAuto .OR. !lEstReq

Static Function NextDoc()
	Local aSvAlias   := GetArea()
	Local aSvAliasD3 := SD3->(GetArea())
	Local cDoc := Space(TamSx3("D3_DOC")[1])

	SD3->(DbSetOrder(2))
	cDoc := NextNumero("SD3",2,"D3_DOC",.T.)
	While SD3->(DbSeek(xFilial("SD3")+cDoc))
		cDoc := Soma1(cDoc,Len(SD3->D3_DOC))
	Enddo

	RestArea(aSvAliasD3)
	RestArea(aSvAlias)
Return cDoc

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A166AvalEm³ Autor ³ Flavio Luiz Vicco     ³ Data ³ 08/03/08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Valida se pode baixar o empenho e campo _TRT               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ A166AvalEm(lEstorno)                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametro ³ lEstorno = .T. - Estorno                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Array = Empenhos                                           ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ ACDV166                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function A166AvalEm(lEstorno)
	Local aEmp     := {}
	Local n1       := 0
	Local nTam     := TamSx3("CB7_OP")[1]
	Local aAreaCB8 := CB8->(GetArea())
	Local aAreaSD4 := SD4->(GetArea())
	Local aAreaSDC := SDC->(GetArea())
	CB8->(DbSetOrder(6))
	SDC->(DbSetOrder(2))
	SD4->(DbSetOrder(2))
	SD4->(DbSeek(xFilial('SD4')+CB7->CB7_OP))
	While SD4->(!Eof() .And. D4_FILIAL+Left(D4_OP,nTam) == xFilial('SD4')+CB7->CB7_OP)
		If	If(lEstorno,.T.,SD4->D4_QUANT > 0)
			If !CBArmProc(SD4->D4_COD,cTM) .AND. Localiza(SD4->D4_COD)
				SDC->(DbSeek(SD4->(xFilial('SDC')+D4_COD+D4_LOCAL+D4_OP+D4_TRT)))
				While SDC->(!Eof() .And. DC_FILIAL+DC_PRODUTO+DC_LOCAL+DC_OP+DC_TRT == SD4->(xFilial('SD4')+D4_COD+D4_LOCAL+D4_OP+D4_TRT))
					If	If(lEstorno,.T.,SDC->DC_QUANT > 0)
						If	(n1:=aScan(aEmp,{|x| x[1]+x[2]==SDC->(DC_PRODUTO+DC_TRT)}))==0
							SDC->(aAdd(aEmp,{DC_PRODUTO, DC_LOCAL, DC_LOCALIZ, DC_LOTECTL, DC_NUMLOTE, If(lEstorno,DC_QTDORIG,DC_QUANT), DC_TRT}))
						Else
							aEmp[n1,6] += SDC->DC_QUANT
						EndIf
					EndIf
					SDC->(DbSkip())
				EndDo
			ElseIf CBArmProc(SD4->D4_COD,cTM)
				CB8->(DBSeek(xFilial("CB8")+CB7->CB7_OP))
				While CB8->(!Eof() .AND. CB8_FILIAL+CB8_OP == xFilial("CB8")+CB7->CB7_OP)
					If (CB8->CB8_PROD <> SD4->D4_COD)
						CB8->(DbSkip())
						Loop
					Endif
					If	(n1:=aScan(aEmp,{|x| x[1]+x[2]+x[3]+x[4]+x[5]==CB8->(CB8_PROD+CB8_LOCAL+CB8_LCALIZ+CB8_LOTECT+CB8_NUMLOT)}))==0
						CB8->(aAdd(aEmp,{CB8_PROD, CB8_LOCAL, CB8_LCALIZ, CB8_LOTECT, CB8_NUMLOT, If(lEstorno,CB8_QTDORI,CB8_QTDORI), SD4->D4_TRT}))
					Else
						aEmp[n1,6] += CB8->CB8_QTDORI
					EndIf
					CB8->(DbSkip())
				Enddo
			Else
				If	(n1:=aScan(aEmp,{|x| x[1]+x[2]==SD4->(D4_COD+D4_TRT)}))==0
					SD4->(aAdd(aEmp,{D4_COD, D4_LOCAL, Space(TamSX3("BF_LOCALIZ")[01]), D4_LOTECTL, D4_NUMLOTE, If(lEstorno,D4_QTDEORI,D4_QUANT), D4_TRT}))
				Else
					aEmp[n1,6] += SD4->D4_QUANT
				EndIf
			EndIf
		EndIf
		SD4->(DbSkip())
	EndDo
	RestArea(aAreaSDC)
	RestArea(aAreaSD4)
	RestArea(aAreaCB8)
Return aEmp

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A166VldCB9³ Autor ³ Felipe Nunes de Toledo³ Data ³ 15/02/07 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Valida se a etiqueta ja foi separada.                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ A166VldCB9(cProd, cCodEti)                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametro ³ cProd     = Cod. Produto                                   ³±±
±±³          ³ cCodEti   = Cod. Etiqueta                                  ³±±
±±³          ³ lPreSep   = Verifica Pre-Separacao                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Logico = (.T.) Ja separada  / (.F.) Nao separada           ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ ACDV166 / ACDV165                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function A166VldCB9(cProd, cCodEti, lPreSep)
	Local cSeekCB9  := ""
	Local lRet      := .F.
	Local aArea     := { CB7->(GetArea()), CB9->(GetArea()) }

	Default lPreSep := .F.

	CB9->(DbSetOrder(3))
	If CB9->(DbSeek(cSeekCB9 := xFilial("CB9")+cProd+cCodEti))
		If lPreSep
			lRet := .T.
		EndIf
		Do While !lRet .And. CB9->(CB9_FILIAL+CB9_PROD+CB9_CODETI) == cSeekCB9
			CB7->(DbSetOrder(1))
			If CB7->(DbSeek(xFilial("CB7")+CB9->CB9_ORDSEP)) .And. !("09*" $ CB7->CB7_TIPEXP)
				lRet := .T.
				Exit
			EndIf
			CB9->(dbSkip())
		EndDo
	EndIf

	RestArea(aArea[1])
	RestArea(aArea[2])
Return lRet

// -------------------------------------------------------------------------------------
/*/{Protheus.doc} SubNSer
Faz a troca do numero de serie selecionado pelo sistema na liberação do PV;
 pelo numero de serie lido pelo operador no ato da separacao

@author: Aecio Ferreira Gomes
@since: 25/09/2013
@Obs: ACDV166
/*/
// -------------------------------------------------------------------------------------
Static Function SubNSer(cLote,cSLote,cEndNew,cNumSer,cSequen)
	Local aSvAlias		:= GetArea()
	Local aSvSC5		:= SC5->(GetArea())
	Local aSvSC6		:= SC6->(GetArea())
	Local aSvSC9		:= SC9->(GetArea())
	Local aSvCB8		:= CB8->(GetArea())
	Local aSvSB7		:= SB7->(GetArea())
	Local aSvCB9		:= CB9->(GetArea())
	Local aCampos		:= {}
	Local aDados		:= {}
	Local cAlias1 		:= "TMPNSSUG"
	Local cAlias2 		:= "TMPNSLIDO"
	Local nQuant 		:= 0
	Local nQuant2       := 0
	Local nBaixa        := 0
	Local nBaixa2		:= 0
	Local nPos			:= 0
	Local nX			:= 0
	Local lRastro		:= .F.

	Default cSequen		:= ""

	If Select(cAlias1) <= 0
		Return
	EndIf

	If (cAlias1)->REG > 0
		lRastro := Rastro((cAlias1)->DC_PRODUTO)

		Begin Transaction

			If Select(cAlias2) > 0 .And. (cAlias2)->REG > 0

				If SC9->(dbSeek(xFilial("SC9")+(cAlias2)->(DC_PEDIDO+DC_ITEM+DC_SEQ+DC_PRODUTO)))

					// Atualiza a liberação do pedido de vendas quando produto controlar lote e for diferente do lote sugerido
					If lRastro .And. (cAlias2)->(DC_LOTECTL+DC_NUMLOTE) # (cAlias1)->(DC_LOTECTL+DC_NUMLOTE)
						AtuLibPV(@cSequen,cAlias1,"DC_LOTECTL","DC_NUMLOTE")
					EndIf

					// Atualiza o empenho
					aCampos := SDC->(dbStruct())
					SDC->(dbGoTo((cAlias1)->REG))
					RecLock("SDC",.F.)
					SDC->(dbDelete())
					SDC->(MsUnlock())

					RecLock("SDC",.T.)
					For nX:= 1 To Len(aCampos)
						If (aCampos[nX,1] $ "DC_LOTECTL|DC_NUMLOTE|DC_LOCALIZ|DC_NUMSERI")
							&(aCampos[nX,1]) := (cAlias2)->&(aCampos[nX,1])
							Loop
						EndIf
						If(aCampos[nX,1] $ "DC_SEQ|DC_TRT")
							&(aCampos[nX,1]) := cSequen
							Loop
						EndIf
						&(aCampos[nX,1]) := (cAlias1)->&(aCampos[nX,1])
					Next
					SDC->(MsUnlock())
				EndIf

				If SC9->(dbSeek(xFilial("SC9")+(cAlias1)->(DC_PEDIDO+DC_ITEM+DC_SEQ+DC_PRODUTO)))

					// Atualiza a liberação do pedido de vendas quando produto controlar lote e for diferente do lote sugerido
					If lRastro .And. (cAlias2)->(DC_LOTECTL+DC_NUMLOTE) # (cAlias1)->(DC_LOTECTL+DC_NUMLOTE)
						AtuLibPV(@cSequen,cAlias2,"DC_LOTECTL","DC_NUMLOTE")
					EndIf

					// Atualiza o empenho
					aCampos := SDC->(dbStruct())
					SDC->(dbGoTo((cAlias2)->REG))
					RecLock("SDC",.F.)
					SDC->(dbDelete())
					SDC->(MsUnlock())

					RecLock("SDC",.T.)
					For nX:= 1 To Len(aCampos)
						If (aCampos[nX,1] $ "DC_LOTECTL|DC_NUMLOTE|DC_LOCALIZ|DC_NUMSERI")
							&(aCampos[nX,1]) := (cAlias1)->&(aCampos[nX,1])
							Loop
						EndIf
						If(aCampos[nX,1] $ "DC_SEQ|DC_TRT")
							&(aCampos[nX,1]) := cSequen
							Loop
						EndIf
						&(aCampos[nX,1]) := (cAlias2)->&(aCampos[nX,1])
					Next
					SDC->(MsUnlock())
				EndIf
				// Guarda os dados do registro lido
				cLote	:= (cAlias2)->DC_LOTECTL
				cSLote	:= (cAlias2)->DC_NUMLOTE
				cEndNew	:= (cAlias2)->DC_LOCALIZ
			Else
				If SC9->(dbSeek(xFilial("SC9")+(cAlias1)->(DC_PEDIDO+DC_ITEM+DC_SEQ+DC_PRODUTO)))

					//---------------------------------------------------------------------------
					// Apaga empenho do numero de serie sugerido e atualiza os saldos
					//---------------------------------------------------------------------------
					// Deleta empenho da tabela SDC
					SDC->(dbGoto((cAlias1)->REG))
					RecLock("SDC")
					SDC->(dbDelete())
					MsUnlock()

					// Atualiza empenhos da tabela SB8
					If lRastro
						cSeek := xFilial("SB8")+(cAlias1)->(DC_PRODUTO+DC_LOCAL+DC_LOTECTL+If(Rastro( (cAlias1)->(DC_PRODUTO) , "S"), DC_NUMLOTE, "") )
						nQuant := (cAlias1)->DC_QUANT
						nQuant2 := (cAlias1)->DC_QTSEGUM
						SB8->(dbSetOrder(3))
						If SB8->(dbSeek(cSeek))
							If Rastro((cAlias1)->(DC_PRODUTO), "S")
								SB8->( GravaB8Emp("-",nQuant,"F",.T.,nQuant2) )
							Else
								Do While SB8->(!Eof() .And. B8_FILIAL+B8_PRODUTO+B8_LOCAL+B8_LOTECTL == cSeek) .And. nQuant > 0
									//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
									//³ Baixa o empenho que conseguir neste lote   ³
									//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
									nBaixa := Min(SB8->B8_EMPENHO,nQuant)
									nBaixa2:= Min(SB8->B8_EMPENH2,nQuant2)
									nQuant -= nBaixa
									nQuant2 -= nBaixa2
									SB8->(GravaB8Emp("-",nBaixa,"F",.T.,nBaixa2))
									SB8->(dbSkip())
								EndDo
							EndIf
						EndIf
					EndIf

					// Atualiza empenhos da tabela SBF
					SBF->(dbSetOrder(4))
					If SBF->(dbSeek(xFilial("SBF")+(cAlias1)->(DC_PRODUTO+DC_NUMSERIE)))
						SBF->(GravaBFEmp("-",1,"F",.T.,(cAlias1)->DC_QTSEGUM))
					EndIf

					// Atualiza empenhos da tabela SB2
					SB2->(dbSetOrder(1))
					If SB2->(dbSeek(xFilial("SB2")+(cAlias1)->(DC_PRODUTO+DC_LOCAL)))
						SB2->(GravaB2Emp("-",1,"F",.T.,(cAlias1)->DC_QTSEGUM))
					EndIf

					//---------------------------------------------------------------------------
					// Grava empenho do numero de serie lido para o pedido de vendas
					//---------------------------------------------------------------------------
					SBF->(dbSetOrder(4))
					SBF->(dbSeek(xFilial("SBF")+(cAlias1)->(DC_PRODUTO)+cNumSer))

					// Atualiza a liberação do pedido de vendas quando produto controlar lote e for diferente do lote sugerido
					If lRastro .And. SBF->(BF_LOTECTL+BF_NUMLOTE) # (cAlias1)->(DC_LOTECTL+DC_NUMLOTE)
						AtuLibPV(@cSequen,"SBF","BF_LOTECTL","BF_NUMLOTE")
					EndIf

					SBF->(GravaEmp(BF_PRODUTO,;  //-- 01.C¢digo do Produto
					BF_LOCAL,;    	//-- 02.Local
					BF_QUANT,;   	//-- 03.Quantidade
					BF_QTSEGUM,;  //-- 04.Quantidade
					BF_LOTECTL,;  //-- 05.Lote
					BF_NUMLOTE,;  //-- 06.SubLote
					BF_LOCALIZ,;  //-- 07.Localiza‡Æo
					BF_NUMSERIE,; //-- 08.Numero de S‚rie
					Nil,;         	//-- 09.OP
					cSequen,;        	//-- 10.Seq. do Empenho/Libera‡Æo do PV (Pedido de Venda)
					(cAlias1)->DC_PEDIDO,;  	//-- 11.PV
					(cAlias1)->DC_ITEM,;     	//-- 12.Item do PV
					'SC6',;       	//-- 13.Origem do Empenho
					Nil,;        	//-- 14.OP Original
					Nil,;			//-- 15.Data da Entrega do Empenho
					NIL,;			//-- 16.Array para Travamento de arquivos
					.F.,;     	   	//-- 17.Estorna Empenho?
					.F.,;         	//-- 18.? chamada da Proje‡Æo de Estoques?
					.T.,;         	//-- 19.Empenha no SB2?
					.F.,;         	//-- 20.Grava SD4?
					.T.,;         	//-- 21.Considera Lotes Vencidos?
					.T.,;         //-- 22.Empenha no SB8/SBF?
					.T.))         //-- 23.Cria SDC?

					// Guarda os dados do registro lido
					cLote	:= SBF->BF_LOTECTL
					cSLote	:= SBF->BF_NUMLOTE
					cEndNew	:= SBF->BF_LOCALIZ
				EndIf
			EndIf

		End Transaction
	EndIf

	RestArea(aSvAlias)
	RestArea(aSvSC5)
	RestArea(aSvSC6)
	RestArea(aSvSC9)
	RestArea(aSvCB8)
	RestArea(aSvSB7)
	RestArea(aSvCB9)
Return

// -------------------------------------------------------------------------------------
/*/{Protheus.doc} AtuLibPV
Atualiza a liberação do pedido de vendas

@param: cSequen - Sequencia do item da liberação
		 cArqTRB - Alias do arquivo que contem os dados do item de troca do numero de serie
		 cCPOlote - Coluna do arquivo que contem o dado do Lote
		 cCPONLote - Coluna do arquivo que contem o dado do SubLote

@author: Aecio Ferreira Gomes
@since: 25/09/2013
@Obs: ACDV166
/*/
// -------------------------------------------------------------------------------------
Static Function AtuLibPV(cSequen, cArqTRB, cCPOLote, cCPONLote)
	Local aArea		:= GetArea()
	Local aCampos	:= {}
	Local aDados 	:= {}
	Local nX		:= 0
	Local cChave	:= ""
	Local cProduto	:= SC9->C9_PRODUTO

	cSequen := SC9->C9_SEQUEN
	cChave	:= SC9->(xFilial("SC9")+C9_PEDIDO+C9_ITEM)

	aCampos := SC9->(dbStruct())
	For nX := 1 To Len(aCampos)
		AADD(aDados,{aCampos[nX,1], SC9->&(aCampos[nX,1])})
	Next nX

	If SC9->C9_QTDLIB > 1
		Reclock("SC9",.F.)
		SC9->C9_QTDLIB -= 1
		MsUnlock()
	Else
		Reclock("SC9",.F.)
		SC9->(dbdelete())
		MsUnlock()
	EndIf

// Recupera a proxima sequencia livre
	While SC9->(dbSeek(cChave+cSequen+cProduto))
		cSequen := Soma1(SC9->C9_SEQUEN)
	End

	RecLock("SC9",.T.)
	For nX:= 1 To Len(aDados)
		Do Case
		Case aDados[nX,1] == "C9_LOTECTL"
			&(aDados[nX,1]) := (cArqTRB)->&(cCPOLote)
		Case aDados[nX,1] == "C9_NUMLOTE"
			&(aDados[nX,1]) := (cArqTRB)->&(cCPONLote)
		Case aDados[nX,1] $ "C9_SEQUEN"
			&(aDados[nX,1]) := cSequen
		Case aDados[nX,1] == "C9_QTDLIB"
			&(aDados[nX,1]) := 1
		OtherWise
			&(aDados[nX,1]) := aDados[nX,2]
		EndCase
	Next nX
	MsUnlock()

	RestArea(aArea)
Return

// -------------------------------------------------------------------------------------
/*/{Protheus.doc} v166TcLote
Efetua a troca dos lotes na liberacao do pedido de vendas.

@param: cOrdSep - Numero da ordem de separacao

@author: Anieli Rodrigues
@since: 15/12/2013
@Obs: ACDV166
/*/
// -------------------------------------------------------------------------------------

Static Function v166TcLote(cOrdSep)

	Local aAreaCB7 		:= CB7->(GetArea())
	Local aAreaCB8 		:= CB8->(GetArea())
	Local aAreaCB9 		:= CB9->(GetArea())
	Local aAreaSC6 		:= SC6->(GetArea())
	Local aAreaSC9 		:= SC9->(GetArea())
	Local aEmpPronto 	:= {}
	Local aItensTrc 	:= {}
	Local lLoteSug 		:= .F.
	Local nQtdSep		:= 0
	Local nX			:= 0
	Local nPos			:= 0
	Local nSaldoLote 	:= 0
	Local cItemAnt   	:= ""
	Local cQuery     	:= ""
	Local cAliasSC9  	:= ""

	CB9->(DbSetOrder(1))
	SC6->(DbSetOrder(1))
	CB7->(DbSetOrder(1))
	CB7->(MsSeek(xFilial("CB7")+cOrdSep))
	CB9->(MsSeek(xFilial("CB9")+cOrdSep))
	SC6->(MsSeek(xFilial("SC6")+CB9->CB9_PEDIDO+CB9->CB9_ITESEP))

	While !CB9->(Eof()) .And. CB9->CB9_ORDSEP == cOrdSep
		If CB9->CB9_LOTECT != CB9->CB9_LOTSUG
			nPos := aScan (aItensTrc,{|x| x[1]+x[2]+x[3]+x[5] == CB9->CB9_PEDIDO+CB9->CB9_ITESEP+CB9->CB9_SEQUEN+CB9->CB9_LOTECT})
			If nPos == 0
				aAdd(aItensTrc, {CB9->CB9_PEDIDO, CB9->CB9_ITESEP, CB9->CB9_SEQUEN, CB9->CB9_QTESEP, CB9->CB9_LOTECT, CB9->CB9_NUMLOT,CB9->CB9_PROD, CB9->CB9_LOCAL})
				nQtdSep += CB9->CB9_QTESEP
			Else
				aItensTrc[nPos][4] 	+= CB9->CB9_QTESEP
				nQtdSep 			+= CB9->CB9_QTESEP
			EndIf
			CB9->(DbSkip())
		Else
			CB9->(DbSkip())
		EndIf
	EndDo

	SC9->(DbSetOrder(1))

	For nx := 1 to Len(aItensTrc)
		nSaldoLote := SaldoLote(aItensTrc[nX][7],aItensTrc[nX][8],aItensTrc[nX][5],aItensTrc[nX][6],,,,dDataBase,,)
		If nSaldoLote < aItensTrc[nX][4]
			VtAlert("Saldo do lote insuficiente." + Alltrim(aItensTrc[nX][5]) + "Sera utilizado o lote original da liberacao do pedido" ,"ATENCAO") //"Saldo do lote insuficiente. Sera utilizado o lote original da liberacao do pedido"
			lLoteSug := .T.
			Exit
		EndIf
		If !lLoteSug .And. SC9->(MsSeek(xFilial("SC9")+aItensTrc[nX][1]+aItensTrc[nX][2]+aItensTrc[nX][3]))
			SC9->(a460Estorna())
		EndIf
	Next nX

	CB9->(DbSetOrder(11)) // CB9_FILIAL+CB9_ORDSEP+CB9_ITESEP+CB9_PEDIDO
	CB7->(DbSetOrder(1))	 // CB7_FILIAL+CB7_ORDSEP
	CB7->(MsSeek(xFilial("CB7")+cOrdSep))
	CB9->(MsSeek(xFilial("CB9")+cOrdSep))

	If !lLoteSug
		For nX := 1 to Len(aItensTrc)
			If SC6->(MsSeek(xFilial("SC6")+aItensTrc[nX][1]+aItensTrc[nX][2]))
				If cItemAnt != aItensTrc[nX][1]+aItensTrc[nX][2]
					aEmpPronto := LoadEmpEst(.F.,.T.)
					MaLibDoFat(SC6->(Recno()),nQtdSep,.T.,.T.,.F.,.F.,.F.,.F.,NIL,{||SC9->C9_ORDSEP := cOrdSep},aEmpPronto,.T.)
				EndIf
			EndIf
			cItemAnt := aItensTrc[nX][1]+aItensTrc[nX][2]
		Next nX
	EndIf

	RestArea(aAreaCB7)
	RestArea(aAreaCB8)
	RestArea(aAreaCB9)
	RestArea(aAreaSC6)
	RestArea(aAreaSC9)

Return

// -------------------------------------------------------------------------------------
/*/{Protheus.doc} A166AvalLb
Realiza a avaliação da liberação/estorno

@param: aEmp - Relação de Empenho
@param: aItensDiverg - Relação de Itens com Divergência

@author: Robson Sales
@since: 03/01/2014
@Obs: ACDV166
/*/
// -------------------------------------------------------------------------------------
Static Function A166AvalLb(aEmp,aItensDiverg)

	Local nX


	If !Empty(aItensDiverg)

		SC9->(DbSetOrder(1))
		If SC9->(DbSeek(xFilial("SC9")+aItensDiverg[1]+aItensDiverg[2]+aItensDiverg[8])) //C9_FILIAL+C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_PRODUTO
			SC9->(a460Estorna())	 //estorna o que estava liberado no sdc e sc9
		EndIf
		// NAO LIBERA CREDITO NEM ESTOQUE...ITEM COM DIVERGENCIA APONTADA (MV_DIVERPV)
		MaLibDoFat(SC6->(Recno()),0,.F.,.F.,.F.,.F.,	.F.,.F.,	NIL,{||SC9->C9_ORDSEP := Space(TamSx3("C9_ORDSEP")[1])},aEmp,.T.)

	Else
		// LIBERA NOVAMENTE COM OS NOVOS LOTES
		MaLibDoFat(SC6->(Recno()),nQtdLib,.T.,.T.,.F.,.F.,	.F.,.F.,	NIL,{||SC9->C9_ORDSEP := cOrdSep},aEmp,.T.)

	End If

Return

// -------------------------------------------------------------------------------------
/*/{Protheus.doc} A166RetEti1
Retorno o codigo da etiqueta interna (CB0_CODETI) ou do cliente (CB0_CODET2)
dependendo do cID passado.

@param: cID - Numero da etiqueta

@author: Robson Sales
@since: 07/05/2014
@Obs: ACDV166
/*/
// -------------------------------------------------------------------------------------
Static Function A166RetEti(cID)

	Local cEtiqueta := ""
	Local aAreaCB0 := CB0->(GetArea())

	If Len(Alltrim(cID)) <=  TamSx3("CB0_CODETI")[1]
		CB0->(DbSetOrder(1))
		CB0->(MsSeek(xFilial("CB0")+Padr(cID,TamSx3("CB0_CODETI")[1])))
		cEtiqueta := CB0->CB0_CODET2
	ElseIf Len(Alltrim(cID)) ==  TamSx3("CB0_CODET2")[1]-1   // Codigo Interno  pelo codigo do cliente
		CB0->(DbSetOrder(2))
		CB0->(MsSeek(xFilial("CB0")+Padr(cID,TamSx3("CB0_CODET2")[1])))
		cEtiqueta := CB0->CB0_CODETI
	EndIf

	RestArea(aAreaCB0)

Return cEtiqueta

// -------------------------------------------------------------------------------------
/*/{Protheus.doc} a166DtVld
Retorna a data de validade do lote

@param:  cProd    - Codigo do produto
          cLocal   - Armazém
          cLote    - Lote
          cSubLote - SubLote

@author: Isaias Florencio
@since: 06/10/2014
/*/
// -------------------------------------------------------------------------------------
Static Function a166DtVld(cProd,cLocal,cLote,cSubLote)
	Local aAreaAnt := GetArea()
	Local aAreaSB8 := SB8->(GetArea())
	Local dDtVld   := CTOD("")

// Indice 3 - SB8 - FILIAL + PRODUTO + LOCAL + LOTECTL + NUMLOTE + DTOS(B8_DTVALID)
	dDtVld := Posicione("SB8",3,xFilial("SB8")+cProd+cLocal+cLote+cSubLote,"B8_DTVALID")

	RestArea(aAreaSB8)
	RestArea(aAreaAnt)
Return dDtVld

// -------------------------------------------------------------------------------------
/*/{Protheus.doc} a166VldSC9
Verifica se existe registro na SC9

@param:    nOrdem - Ordem de pesquisa
			cChave - Chave de pesquisa

@author: Isaias Florencio
@since: 06/10/2014
/*/
// -------------------------------------------------------------------------------------
Static Function a166VldSC9(nOrdem,cChave)
	Local aAreaAnt := GetArea()
	Local aAreaSC9 := SC9->(GetArea())
	Local lRet     := .F.

	SC9->(DbSetOrder(nOrdem))
	lRet := SC9->(MsSeek(xFilial("SC9")+cChave))

	RestArea(aAreaSC9)
	RestArea(aAreaAnt)
Return lRet

// -------------------------------------------------------------------------------------
/*/{Protheus.doc} A166GetEnd
Obtém endereco do produto a ser estornado

@param:    cArmazem  - codigo do armazem
           cEndereco - codigo do endereco a ser obtido

@author: Isaias Florencio
@since:  22/01/2015
/*/
// -------------------------------------------------------------------------------------

Static Function A166GetEnd(cArmazem,cEndereco)
	Local aAreaAnt := GetArea()
	Local aSave    := VTSAVE()
	IF !Type("lVT100B") == "L"
		Private lVT100B := .F.
	EndIf

	VtRestore(,,,,aSave)

	RestArea(aAreaAnt)

Return Nil

// -------------------------------------------------------------------------------------
/*/{Protheus.doc} A166MtaEst
Monta tela de estorno até o termino do processo

@param:    cEProduto - Produto da etiqueta
			nQtde     - Quantidade
			cArmazem  - codigo do armazem
           	cEndereco - codigo do endereco a ser obtido
          	cVolume   - Volume informado.

@author: Andre Maximo
@since:  03/05/2016
/*/
// -------------------------------------------------------------------------------------

Static Function A166MtaEst(nQtde,cArmazem,cEndereco,cVolume,nOpc)

	Local aSave	     := VTSave()
	Local aAreaAnt   := GetArea()
	Local cEtiqEnd   := Space(20)
	Local cProduto   := Space(48)
	Local cIdVol     := Space(10)
	Local lLocaliz := SuperGetMV("MV_LOCALIZ") == "S"
	IF !Type("lVT100B") == "L"
		Private lVT100B := .F.
	EndIf
	Default nQtde     := 1
	Default cArmazem  := Space(Tamsx3("B1_LOCPAD")[1])
	Default cEndereco	 := Space(TamSX3("BF_LOCALIZ")[1])
	Default cVolume	 := Space(10)
	Default nOpc       := 1


	VtClear
	@ 0,0 VtSay Padc("Estorno da leitura",VTMaxCol()) //"Estorno da leitura"
	If lVT100B // GetMv("MV_RF4X20")
		While .T.
			VTClear(1,0,3,19)
			If "01" $ CB7->CB7_TIPEXP
				@ 2,0 VTSay "Leia o volume" VTGet cIdVol pict "@!" Valid VldVolEst(cIdVol,@cVolume) when IIF(!Empty(cVolume), .F., .T.) .and. iif(lVolta .and. lForcaQtd,(VTKeyBoard(chr(13)),.T.),.T.) //"Leia o volume"
				//@ 3,0 VTGet cIdVol pict "@!" Valid VldVolEst(cIdVol,@cVolume) when IIF(!Empty(cVolume), .F., .T.)
			EndIf

			cProduto   := Space(48)
			cKey21  := VTDescKey(21)
			bKey21  := VTSetKey(21)

			@ 3,0 VTSay "Qtde " VtGet nQtde PICTURE cPictQtdExp valid nQtde > 0 when (lForcaQtd .or. VtLastkey()==5, lVolta := .F.) //"Qtde "

			If !(vtLastKey() == 27)
				//segunda tela
				lVolta := .F.
				VTClear(1,0,3,19)
				//@ 0,0 VTSay STR0047 VtGet nQtde PICTURE cPictQtdExp valid nQtde > 0 when (lForcaQtd .or. VtLastkey()==5) //"Qtde "
				@ 1,0 VTSay "Leia o produto" //"Leia o produto"
				@ 2,0 VTGet cProduto PICTURE "@!" VALID VTLastkey() == 5 .or. VldEstEnd(cProduto,@nQtde,cArmazem,cEndereco,cVolume,nOpc)
			EndIf

			If lVolta
				Loop
			EndIf
		EndDo
	Else
		If "01" $ CB7->CB7_TIPEXP
			If VTModelo()=="RF"
				@ 3,0 VTSay "Leia o volume" //"Leia o volume"
				@ 4,0 VTGet cIdVol pict "@!" Valid VldVolEst(cIdVol,@cVolume) when IIF(!Empty(cVolume), .F., .T.)
			Else
				@ 1,0 Vtclear to 1,VtMaxCol()
				@ 1,0 VTSay "Volume" VTGet cIdVol pict "@!" Valid VldVolEst(cIdVol,@cVolume) when IIF(!Empty(cVolume), .F., .T.) //"Volume"
				VtRead
				If VtLastKey() == 27
					VTRestore(,,,,aTela)
					Return .f.
				Endif
			EndIf
		EndIf
		cProduto   := Space(48)
		cKey21  := VTDescKey(21)
		bKey21  := VTSetKey(21)

		@ 5,0 VTSay "Qtde " VtGet nQtde PICTURE cPictQtdExp valid nQtde > 0 when (lForcaQtd .or. VtLastkey()==5) //"Qtde "
		@ 6,0 VTSay "Leia o produto" //"Leia o produto"
		@ 7,0 VTGet cProduto PICTURE "@!" VALID VTLastkey() == 5 .or. VldEstEnd(cProduto,@nQtde,cArmazem,cEndereco,cVolume,nOpc)
		VtRead()
	Endif
	VTSetKey(21,bKey21,cKey21)

	If VtLastKey() == 27
		VTRestore(,,,,aSave)
		Return .f.
	Endif

	VtRestore(,,,,aSave)
	RestArea(aAreaAnt)

Return Nil
/*/{Protheus.doc} A166GetSld
Valida saldo disponivel por lote x saldo jah coletado

@param: cOrdSep,cProd,cArmazem,cEndereco,cLote,cSLote,cNumSer
Ordem de separacao, Produto,Armazem, endereco, lote, sublote e numero de serie

@author: Isaias Florencio
@since:  02/03/2015
/*/
// -------------------------------------------------------------------------------------

Static Function A166GetSld(cOrdSep,cProd,cArmazem,cEndereco,cLote,cSLote,cNumSer)
	Local aAreaAnt  := GetArea()
	Local nSaldo    := 0
	Local lRet      := .T.
	Local cAliasTmp := GetNextAlias()
	Local cQuery    := ""

	cQuery := "SELECT SUM(CB9.CB9_QTESEP) AS QTESEP FROM "+ RetSqlName("CB9")+" CB9 WHERE "
	cQuery += "CB9.CB9_FILIAL	= '" + xFilial('CB9') + "' AND "
	cQuery += "CB9.CB9_ORDSEP	= '" + cOrdSep        + "' AND CB9.CB9_PROD   = '"+ cProd     + "' AND "
	cQuery += "CB9.CB9_LOCAL	= '" + cArmazem       + "' AND CB9.CB9_LCALIZ = '"+ cEndereco + "' AND "
	cQuery += "CB9.CB9_LOTECT	= '" + cLote          + "' AND CB9.CB9_NUMLOT = '"+ cSLote    + "' AND "
	cQuery += "CB9.CB9_NUMSER	= '" + cNumSer        + "' AND CB9.D_E_L_E_T_ = ' ' "

	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTmp,.T.,.T.)

	nSaldo := (cAliasTmp)->QTESEP

	nSaldoAtu := SaldoLote(cProd,cArmazem,cLote,cSLote,,,,dDataBase,,)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Se jah houver saldo separado na CB9, verifica se saldo eh menor ³
//³ ou igual ao saldo disponivel, devido a funcao SaldoLote() nao   |
//³ considerar saldos separados na CB9. Caso ainda nao tenha havido |
//³ separacoes na CB9, faz verificacao simples (menor)              |
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If nSaldo > 0
		lRet := !(nSaldoAtu <= nSaldo)
	Else
		lRet := !(nSaldoAtu < nSaldo)
	EndIf

	(cAliasTmp)->(DbCloseArea())

	RestArea(aAreaAnt)
Return lRet

// -------------------------------------------------------------------------------------
/*/{Protheus.doc} A166EndLot
Verifica se lote pertence ao endereco da OS

.T. = pertence ao mesmo endereco
.F. = nao pertence ao endereco da OS

@param: Produto, Lote, Sublote, Numero de serie, armazem e endereco da CB8

@author: Isaias Florencio
@since:  16/03/2015
/*/
// -------------------------------------------------------------------------------------

Static Function A166EndLot(cProduto,cLoteProd,cSublote,cNumSerie,cArmazem,cEndereco)
	Local aAreas   := { GetArea(), SBF->(GetArea()) }
	Local lRet	   := .T.

	SBF->(dbSetOrder(1)) //BF_FILIAL+BF_LOCAL+BF_LOCALIZ+BF_PRODUTO+BF_NUMSERI+BF_LOTECTL+BF_NUMLOTE
	If ! SBF->(MsSeek(xFilial("SBF")+cArmazem+cEndereco+cProduto+cNumSerie+cLoteProd+cSublote))
		lRet := .F.
	EndIf

	RestArea(aAreas[2])
	RestArea(aAreas[1])
Return lRet

// -------------------------------------------------------------------------------------
/*/{Protheus.doc} NSerLocal
Valida se a troca de Numero de série está sendo realizada dentro do mesmo armazém

@param cProd,cLocal,cNumSer
@author jose.eulalio
@since 17/07/2018
/*/
// -------------------------------------------------------------------------------------
Static Function NSerLocal(cProd,cLocal,cNumSerNew,cEndNew)
	Local lRet			:= .T.
	Local cAliasNSer	:= GetNextAlias()

	BeginSQL Alias cAliasNSer

SELECT 
	R_E_C_N_O_ AS REG, 
	BF_LOCALIZ AS ENDNEW	
FROM
	%table:SBF%
WHERE
	BF_FILIAL = %xFilial:SBF% AND
	BF_PRODUTO = %Exp:cProd% AND
	BF_LOCAL = %Exp:cLocal% AND
	BF_NUMSERI = %Exp:cNumSerNew% AND
	%notDel%
	EndSQL

	If lRet := Select(cAliasNSer) .And. (cAliasNSer)->REG > 0
		cEndNew := (cAliasNSer)->ENDNEW
	EndIf

	(cAliasNSer)->(DbCloseArea())

Return lRet
