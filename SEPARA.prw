#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "DBTREE.CH"


User Function SEPARA()
	Local lContinua      := .T.
	Private cString      := "CB7"
	Private aOrd         := {}
	Private cDesc1       := "Este programa tem como objetivo imprimir informacoes das" //"Este programa tem como objetivo imprimir informacoes das"
	Private cDesc2       := "Ordens de Separacao" //"Ordens de Separacao"
	Private cPict        := ""
	Private lEnd         := .F.
	Private lAbortPrint  := .F.
	Private limite       := 132
	Private tamanho      := "M"
	Private nomeprog     := "ACDA100R" // Coloque aqui o nome do programa para impressao no cabecalho
	Private nTipo        := 18
	Private aReturn      := {"Zebrado",1,"Administracao",2,2,1,"",1}  //"Zebrado"###"Administracao"
	Private nLastKey     := 0
	Private cPerg        := "ACD100"
	Private titulo       := "Impressao das Ordens de Separacao" //"Impressao das Ordens de Separacao"
	Private nLin         := 06
	Private Cabec1       := ""
	Private Cabec2       := ""
	Private cbtxt        := "Regsitro(s) lido(s)" //"Regsitro(s) lido(s)"
	Private cbcont       := 0
	Private CONTFL       := 01
	Private m_pag        := 01
	Private lRet         := .T.
	Private imprime      := .T.
	Private wnrel        := "ACDA100R" // Coloque aqui o nome do arquivo usado para impressao em disco

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis utilizadas como Parametros                                ³
//³ MV_PAR01 = Ordem de Separacao de       ?                            ³
//³ MV_PAR02 = Ordem de Separacao Ate      ?                            ³
//³ MV_PAR03 = Data de Emissao de          ?                            ³
//³ MV_PAR04 = Data de Emissao Ate         ?                            ³
//³ MV_PAR05 = Considera Ordens encerradas ?                            ³
//³ MV_PAR06 = Imprime Codigo de barras    ?                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	wnrel := SetPrint(cString,NomeProg,cPerg,@titulo,cDesc1,cDesc2,Nil,.F.,aOrd,.F.,Tamanho,,.T.)

	Pergunte(cPerg,.F.)

	If	nLastKey == 27
		lContinua := .F.
	EndIf

	//If	lContinua
		SetDefault(aReturn,cString)
	//EndIf

	If	nLastKey == 27
		lContinua := .F.
	EndIf

	If	lContinua
		RptStatus({|| Relatorio() },Titulo)
	EndIf

	CB7->(DbClearFilter())
Return

Static Function Relatorio()

	CB7->(DbSetOrder(1))
	CB7->(DbSeek(xFilial("CB7")+MV_PAR01,.T.)) // Posiciona no 1o.reg. satisfatorio
	SetRegua(RecCount()-Recno())

	While ! CB7->(EOF()) .and. (CB7->CB7_ORDSEP >= MV_PAR01 .and. CB7->CB7_ORDSEP <= MV_PAR02)
		If CB7->CB7_DTEMIS < MV_PAR03 .or. CB7->CB7_DTEMIS > MV_PAR04 // Nao considera as ordens que nao tiver dentro do range de datas
			CB7->(DbSkip())
			Loop
		Endif
		If MV_PAR05 == 2 .and. CB7->CB7_STATUS == "9" // Nao Considera as Ordens ja encerradas
			CB7->(DbSkip())
			Loop
		Endif
		CB8->(DbSetOrder(1))
		If ! CB8->(DbSeek(xFilial("CB8")+CB7->CB7_ORDSEP))
			CB7->(DbSkip())
			Loop
		EndIf
		IncRegua("Imprimindo")  //"Imprimindo"
		If lAbortPrint
			@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***" //"*** CANCELADO PELO OPERADOR ***"
			Exit
		Endif
		Imprime()
		CB7->(DbSkip())
	Enddo
	Fim()
Return

Static Function Imprime(lRet)
	Local cOrdSep := Alltrim(CB7->CB7_ORDSEP)
	Local cPedido := Alltrim(CB7->CB7_PEDIDO)
	Local cCliente:= Alltrim(CB7->CB7_CLIENT)
	Local cLoja   := Alltrim(CB7->CB7_LOJA	)
	Local cNota   := Alltrim(CB7->CB7_NOTA)
	Local cSerie  := Alltrim(CB7->CB7_SERIE)
	Local cOP     := Alltrim(CB7->CB7_OP)
	Local cStatus := RetStatus(CB7->CB7_STATUS)
	Local nWidth  := 0.050
	Local nHeigth := 0.75
	Local oPr
	_cTrans := ""
	Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)

	DbSelectArea("SF2")
	DbSetOrder(1)
	DbSeek(xFilial("SF2")+cNota+cSerie)
	If Found()
		_cTrans := Posicione("SA4",1,xFilial("SA4")+SF2->F2_TRANSP,"SA4->A4_NOME")
	EndIf
	@ 06, 000 Psay "Ordem de Separacao: "+cOrdSep //"Ordem de Separacao: "

	//If !Empty(_cTrans)
	//EndIf

	If CB7->CB7_ORIGEM == "1" // Pedido de Venda
		@ 06, 035 Psay "Pedido de Venda: "+cPedido 	 //"Pedido de Venda: "
		@ 06, 065 Psay "Cliente: "+cCliente+" - "+"Loja: "+cLoja //"Cliente: "###"Loja: "
		@ 06, 095 Psay "Status: "+cStatus //"Status: "
	Elseif CB7->CB7_ORIGEM == "2" // Nota Fiscal de Saida
		@ 06, 035 Psay "Nota Fiscal: "+cNota+" - Serie: "+cSerie //"Nota Fiscal: "###" - Serie: "
		@ 06, 075 Psay "Cliente: "+cCliente+" - "+"Loja: "+cLoja //"Cliente: "###"Loja: "
		@ 06, 108 Psay "Status: "+cStatus //"Status: "
	Elseif CB7->CB7_ORIGEM == "3" // Ordem de Producao
		@ 06, 035 Psay "Ordem de Producao: "+cOP //"Ordem de Producao: "
		@ 06, 070 Psay "Status: "+cStatus //"Status: "
	Endif
	@ 07, 000 Psay "Transportadora: "+_cTrans
	If MV_PAR06 == 1 //.And. aReturn[5] # 1
		oPr := ReturnPrtObj()
		//@ 08 ,001 PSAY 'Codigo 128 subset B'
		MSBAR3("CODE128",1.5,0.5,cOrdSep,oPr,Nil,Nil,Nil,nWidth,nHeigth,.F.,Nil,"B",Nil,Nil,Nil,.f.)
		nLin := 12
	Else
		nLin := 8
	EndIf

	@ ++nLin, 000 Psay Replicate("=",147)
	nLin++

	@nLin, 000 Psay "Produto" //"Produto"
	@nLin, 020 Psay "Descricao" //"Armazem"
	@nLin, 058 Psay "Armazem" //"Armazem"
	@nLin, 070 Psay "Endereco" //"Endereco"
	@nLin, 079 Psay "Lote" //"Lote"
	//@nLin, 070 Psay "SubLote" //"SubLote"
	//@nLin, 079 Psay "Numero de Serie" //"Numero de Serie"
	@nLin, 101 Psay "Qtd Original" //"Qtd Original"
	@nLin, 116 Psay "Qtd a Separar" //"Qtd a Separar"
	//@nLin, 132 Psay "Qtd a Embalar" //"Qtd a Embalar"


	_sQuery := ChangeQuery("SELECT B1_DESC, B1_CONV, * FROM CB8010 CB8, SB1010 SB1 WHERE CB8.D_E_L_E_T_ <> '*' AND SB1.D_E_L_E_T_ <> '*' AND B1_COD = CB8_PROD AND CB8_FILIAL = '"+xFilial("CB8")+"' AND CB8_ORDSEP = '"+cOrdSep+"' ORDER BY CB8_LCALIZ DESC")
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), 'TTS', .f., .t.)
	DbSelectArea("TTS")
	DbGoTop()
	Do While !TTS->(EOF())
		nLin++
		If nLin > 59 // Salto de Página. Neste caso o formulario tem 55 linhas...
			Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
			nLin := 06
			@nLin, 000 Psay "Produto" //"Produto"
			@nLin, 020 Psay "Descricao" //"Armazem"
			@nLin, 058 Psay "Armazem" //"Armazem"
			@nLin, 070 Psay "Endereco" //"Endereco"
			@nLin, 079 Psay "Lote" //"Lote"
			//@nLin, 070 Psay "SubLote" //"SubLote"
			//@nLin, 079 Psay "Numero de Serie" //"Numero de Serie"
			@nLin, 101 Psay "Qtd Original" //"Qtd Original"
			@nLin, 116 Psay "Qtd a Separar" //"Qtd a Separar"
			//@nLin, 132 Psay "Qtd a Embalar" //"Qtd a Embalar"
		Endif
		@nLin, 000 Psay TTS->CB8_PROD
		@nLin, 020 Psay Left(TTS->B1_DESC,30)
		@nLin, 058 Psay TTS->CB8_LOCAL
		@nLin, 070 Psay TTS->CB8_LCALIZ
		@nLin, 079 Psay TTS->CB8_LOTECT
		//@nLin, 070 Psay TTS->CB8_NUMLOT
		//@nLin, 079 Psay TTS->CB8_NUMSER
		@nLin, 099 Psay TTS->CB8_QTDORI/TTS->B1_CONV Picture "@E 999,999,999.99"
		@nLin, 114 Psay TTS->CB8_SALDOS/TTS->B1_CONV Picture "@E 999,999,999.99"
		//@nLin, 130 Psay TTS->CB8_SALDOE Picture "@E 999,999,999.99"
		TTS->(DbSkip())
	EndDo
	TTS->(DbCloseArea())
Return

Static Function Fim()

	SET DEVICE TO SCREEN
	If aReturn[5]==1
		dbCommitAll()
		SET PRINTER TO
		OurSpool(wnrel)
	Endif
	MS_FLUSH()
Return

Static Function RetStatus(cStatus)
	Local cDescri:= " "

	If Empty(cStatus) .or. cStatus == "0"
		cDescri:= "Nao iniciado" //"Nao iniciado"
	ElseIf cStatus == "1"
		cDescri:= "Em separacao" //"Em separacao"
	ElseIf cStatus == "2"
		cDescri:= "Separacao finalizada" //"Separacao finalizada"
	ElseIf cStatus == "3"
		cDescri:= "Em processo de embalagem" //"Em processo de embalagem"
	ElseIf cStatus == "4"
		cDescri:= "Embalagem Finalizada" //"Embalagem Finalizada"
	ElseIf cStatus == "5"
		cDescri:= "Nota gerada" //"Nota gerada"
	ElseIf cStatus == "6"
		cDescri:= "Nota impressa" //"Nota impressa"
	ElseIf cStatus == "7"
		cDescri:= "Volume impresso" //"Volume impresso"
	ElseIf cStatus == "8"
		cDescri:= "Em processo de embarque" //"Em processo de embarque"
	ElseIf cStatus == "9"
		cDescri:=  "Finalizado" //"Finalizado"
	EndIf

Return(cDescri)
