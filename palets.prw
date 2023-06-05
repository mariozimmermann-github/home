#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPRINTSETUP.CH"

//--------------------------------------------------------------------------------------
/*/{Protheus.doc} PALETS
@Type			: Função de Usuário
@Sample			: U_PALETS()
@Description	: Gera etiquetas para Palets e grava este registro na CB0
@Param			: Nenhum
@Return			: Nenhum
@ --------------|-----------------------------------------------------------------------
@Author			: Evandro Mugnol
@Since			: Jan/2023
@version		: Protheus 12.1.33 e posteriores
@Comments		: Nenhum
/*/
//--------------------------------------------------------------------------------------
User Function PALETS()

	Private _oTela
	Private _cTitulo    := OemToAnsi("Impressão de Etiquetas para Palets")
	Private _oFtArial24 := TFont():New ("Arial"      , 10, 24)
	Private _oFCourier  := TFont():New ("Courier New",   , 24,,.T.)
	Private _oFCour014  := TFont():New ("Courier New",   , 18,,.T.)
	Private _cOP    	:= Space(11)
	Private _cLote    	:= Space(10)
	Private _dDtVld		:= Ctod("")
	Private _cProduto   := Space(60)
	Private _cTipoP		:= "  "
	Private _nQuantT    := _nQuantP	:= _nQtdCx	:= _nQntTot	:= 0
	Private _xQTotal	:= Space(30)
	Private _xQPalet	:= Space(30)
	Private _xQNPal		:= Space(30)
	Private _xnTipo		:= 1
	Private _nQTDPL		:= 0

	_xQTotal := {"Quantidade Total Caixas da OP   ","Quantidade Total em KG da OP    "}
	_xQPalet := {"Quantidade Paletizada deste Lote","Quantidade Pesada deste lote    "}
	_xQNPal	 := {"Quantas Caixas neste Palet ?    ","Quantos KG neste BINS ?         "}

	// Dialog de entrada de dados para impressão e gravação da etiqueta de Palet
	DEFINE MSDIALOG _oTela TITLE _cTitulo FROM C(0), C(0) TO C(350), C(435) PIXEL

	@ C(020), C(010) SAY "Número da OP:" 	                        Size C(130), C(10) FONT _oFtArial24 COLOR CLR_GREEN	PIXEL OF _oTela
	@ C(020), C(080) MSGET _cOP Valid Vazio() .Or. _VldOP()			Size C(060), C(10) FONT _oFCourier  COLOR CLR_GREEN	PIXEL OF _oTela
	@ C(035), C(010) SAY "L O T E:"									Size C(130), C(10) FONT _oFtArial24 COLOR CLR_GREEN	PIXEL OF _oTela
	@ C(035), C(080) MSGET _cLote Valid Vazio() .Or. _VldLote()		Size C(060), C(10) FONT _oFCourier  COLOR CLR_GREEN	PIXEL OF _oTela
	@ C(050), C(010) SAY "Data Validade:"                           Size C(130), C(10) FONT _oFtArial24 COLOR CLR_GREEN	PIXEL OF _oTela
	@ C(050), C(080) MSGET _dDtVld Valid NaoVazio()					Size C(060), C(10) FONT _oFCourier  COLOR CLR_GREEN	PIXEL OF _oTela

	@ C(065), C(010) SAY "Produto:"                                 Size C(130), C(10) FONT _oFtArial24 COLOR CLR_GREEN	PIXEL OF _oTela
	@ C(065), C(055) SAY _cProduto									Size C(300), C(10) FONT _oFCourier  COLOR CLR_HBLUE	PIXEL OF _oTela
	@ C(080), C(010) SAY _xQTotal[_xnTipo]         					Size C(130), C(10) FONT _oFtArial24 COLOR CLR_GREEN	PIXEL OF _oTela
	@ C(080), C(150) SAY TRANSFORM(_nQuantT, '@E 99,999')     		Size C(300), C(10) FONT _oFCourier  COLOR CLR_HBLUE	PIXEL OF _oTela
	@ C(095), C(010) SAY "Quantidade Total Paletizada desta OP"		Size C(130), C(10) FONT _oFtArial24 COLOR CLR_GREEN	PIXEL OF _oTela
	@ C(095), C(150) SAY TRANSFORM(_nQntTot, '@E 99,999')      		Size C(300), C(10) FONT _oFCourier  COLOR CLR_HBLUE	PIXEL OF _oTela
	@ C(110), C(010) SAY _xQPalet[_xnTipo]         					Size C(130), C(10) FONT _oFtArial24 COLOR CLR_GREEN	PIXEL OF _oTela
	@ C(110), C(150) SAY TRANSFORM(_nQuantP, '@E 99,999')      		Size C(300), C(10) FONT _oFCourier  COLOR CLR_HBLUE	PIXEL OF _oTela
	@ C(125), C(010) SAY _xQNPal[_xnTipo]      						Size C(130), C(10) FONT _oFtArial24 COLOR CLR_GREEN	PIXEL OF _oTela
	@ C(125), C(140) GET _nQtdCx Valid _VldCx() Picture "@E 99,999"	Size C(050), C(10) FONT _oFCourier  COLOR CLR_GREEN	PIXEL OF _oTela

	@ 200,010 BUTTON "Imprimir Etiqueta" SIZE 080, 020 FONT _oFCour014 PIXEL OF _oTela ACTION (_bOK := .T., _PPalet())
	@ 200,100 BUTTON "Etiqueta Geradas " SIZE 080, 020 FONT _oFCour014 PIXEL OF _oTela ACTION (_bOK := .T., _PaletG(_cOP))
	@ 200,190 BUTTON "Sair" 			 SIZE 080, 020 FONT _oFCour014 PIXEL OF _oTela ACTION (_bOK := .F., _oTela:End())

	ACTIVATE MSDIALOG _oTela CENTERED
	
Return

// Gera Rotulo de Palet e Grava na CB0                      
Static Function _PPalet()

	Local _nLinIni	  := 1
	Local _nColIni	  := 20
	Local _lRet		  := .T.
	Local oFont28 	  := TFont():New("COURIER",,22,.T.,.T.,5,.T.,5,.T.,.F.)
	Local oFont18 	  := TFont():New("COURIER",,18,.T.,.T.,5,.T.,5,.T.,.F.)
	Local oFont23 	  := TFont():New("ARIAL",,23,.T.,.T.,5,.T.,5,.T.,.F.)
	Local oFont12 	  := TFont():New("ARIAL",,26,.T.,.F.,5,.T.,5,.T.,.F.)
	Local _cDiretorio := "\bitmaps\"
	Local _cArquivo	  := _cDiretorio+"Palet.bmp"
	Local oPrint
	Local nBegin

	If Empty(_dDtVld)
		MsgAlert("É Obrigatório informar Data de Validade", "Atenção")
		//_oTela:End ()
		Return(.F.)
	EndIf

	// Acessa SC2 para pegar informações
	DbSelectArea("SC2")
	SC2->(dbSetOrder(1))
	SC2->(DbSeek(xFilial("SC2") + _cOP))
	IF !SC2->(EOF())
		If EMPTY(SC2->C2_DATRF)
			_cCodProd := SC2->C2_PRODUTO
			_cDesProd := POSICIONE('SB1', 1, xFilial('SB1') + SC2->C2_PRODUTO, 'B1_DESC')
			_nConv	  := POSICIONE('SB1', 1, xFilial('SB1') + SC2->C2_PRODUTO, 'B1_CONV')
			_cTipoP	  := POSICIONE('SB1', 1, xFilial('SB1') + SC2->C2_PRODUTO, 'B1_TIPO')
			_mesesVal := POSICIONE('SB1', 1, xFilial('SB1') + SC2->C2_PRODUTO, 'B1_PRVALID')
			_DtFabr	  := DTOC(Date())
			_Lote	 := _cLote
			_QCaixas := _nQtdCx
			_nLinha	 :=	_nLinIni

			// Inicia a Impressão da Etiqueta
			oPrint:= FWMSPrinter():New( "Protheus - Rótulos de Palets")
			oPrint:StartPage()
			oPrint:SayBitmap(_nLinha, _nColIni, _cArquivo, 1100, 1600)
			oPrint:Say(_nLinha + 350, _nColIni+200, _cCodProd, oFont12)

			_nLin    := _nLinha + 440
			nTamDesc := 23
			If Len(_cDesProd) > nTamDesc
				// Imprime descrição do produto quando tem mais que 23 caracteres (2 ou mais linhas)
				nLinTot := MlCount(_cDesProd,nTamDesc)
				
				oPrint:Say(_nLin, _nColIni+60, MemoLine(_cDesProd,nTamDesc,1), 	oFont23)
				For nBegin := 2 To nLinTot
					_nLin += 90
					oPrint:Say(_nLin, _nColIni+60, MemoLine(_cDesProd,nTamDesc,nBegin), oFont23)
				Next nBegin
			Else 
				// Imprime descrição do produto quando tem menos que 23 caracteres (somente 1 linha)
				oPrint:Say(_nLin, _nColIni+60, MemoLine(_cDesProd,nTamDesc,1), 	oFont23)
			EndIf
   
			oPrint:Say(_nLinha + 700, _nColIni+95, "Fabricação:"+_DtFabr, oFont28)
			oPrint:Say(_nLinha + 840, _nColIni+95, "Validade  :"+Dtoc(_dDtVld), oFont28)
			oPrint:Say(_nLinha + 980, _nColIni+95, "Lote      :"+_Lote, oFont28)
			oPrint:Say(_nLinha + 1120, _nColIni+95, "Qtd.Caixas:"+STRZERO(_QCaixas, 5,0), oFont28)
			oPrint:Say(_nLinha + 1260, _nColIni+95, "Nº Pallet :"+strzero(_nQTDPL , 5,0), oFont18)

			_cCodCB0 := CBGrvEti('01',{SC2->C2_PRODUTO,_QCaixas,ALLTRIM(cUserName),NIL,NIL,NIL,NIL,NIL,NIL,SC2->C2_LOCAL,_cOP,NIL,NIL,NIL,NIL,_Lote,NIL,_dDtVld,NIL,NIL,NIL,NIL,NIL,NIL,NIL})
			oPrint:FwMsBar("CODE128", 30.4, 6, Alltrim(_cCodCB0), oPrint, .F., NIL, .T., 0.04, 0.50, .T., "Times New Roman", NIL, .F.)
			oPrint:EndPage()     	// Finaliza a página
			oPrint:Print()			// Imprime Direto

			DbSelectArea("CB0")
			DbSetOrder(1)
			If DBSeek(xFilial("CB0")+_cCodCB0)
				RecLock ("CB0",.F.)
				CB0->CB0_PALLET := STRZERO(_nQTDPL,6,0)
				CB0->CB0_STATUS := 'A'
				MsUnLock ()
			EndIf
			DbSelectArea("SC2")
			_nQuantT := 0
			_nQuantP := 0
		Endif
	Endif

	_cOP      := Space(11)
	_cLote    := Space(10)
	_dDtVld	  := Ctod("")
	_cProduto := Space(60)
	_cTipoP	  := "  "
	_nQuantT  := _nQuantP	:= _nQtdCx	:= _nQntTot	:= 0
	_xnTipo	  := 1
	_nQTDPL	  := 0

	//_oTela:End ()

Return(_lRet)


// Efetua Consistencia da OP                                  
Static Function _VldOP()

	Local _lRet  := .T.
	Local _nConv := 0

	_nQuantP := 0

	DbSelectArea("SC2")
	SC2->(dbSetOrder(1))
	SC2->(DbSeek(xFilial("SC2") + _cOP))
	IF !SC2->(EOF())
		If EMPTY(SC2->C2_DATRF)
			_nConv	  := POSICIONE('SB1', 1, xFilial('SB1') + SC2->C2_PRODUTO, 'B1_CONV')
			_cProduto := POSICIONE('SB1', 1, xFilial('SB1') + SC2->C2_PRODUTO, 'B1_DESC')
			_cTipoP	  := POSICIONE('SB1', 1, xFilial('SB1') + SC2->C2_PRODUTO, 'B1_TIPO')
			_nQuantT  := SC2->C2_QUANT / _nConv
			IF _cTipoP = 'PA'
				_xnTipo := 1
				_nQuantT := SC2->C2_QUANT / _nConv
			elseif _cTipoP = 'PE'
				_xnTipo := 2
				_nQuantT := SC2->C2_QUANT
			EndIf
			DbSelectArea("CB0")
			DbSetOrder(7)
			DbSeek(xFilial("CB0")+_cOP)
			Do While !CB0->(EOF())
				if CB0->CB0_OP = _cOP
					_nQntTot += CB0->CB0_QTDE
				Endif
				CB0->(DbSkip())
			EndDo

			// Aqui testa se a OP já foi completamente anotada mesmo que não esteja encerrada
			DbSelectArea("SC2")
			IF SC2->C2_QUJE >= SC2->C2_QUANT
				MsgAlert("OP já no limite de Produção, Maximo " + Alltrim(str(SC2->C2_QUANT)))
				_lRet := .F.
			Endif
		Else
			_cProduto := Replicate("?",60)
			MsgAlert("Ordem de Produção Já Encerrada. Verifique!!!")
			_lRet := .F.
		Endif
		_cLote := Substr(_cOP,1,2) + "/" + Substr(_cOP,3,4)
	Else
		_cProduto := Replicate("?",60)
		MsgAlert(_cOP+" - Ordem de Produção Não Localizada. Verifique!!!")
		_lRet := .F.
	Endif

Return(_lRet)


// Efetua Consistencia da Lote                                  
Static Function _VldLote()

	Local _lRet := .T.

	_nQTDPL		:= 0
	_nQuantP	:= 0

	_cQuerylt := "SELECT  IsNull(MAX(CB0_PALLET),0) NPAL,  IsNull(SUM(CB0_QTDE),0) NQTD FROM CB0010 WHERE CB0_OP='"+_cOP+"' AND CB0_LOTE='"+_cLote+"' AND D_E_L_E_T_=''"
	_cQuerylt := ChangeQuery(_cQuerylt)
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _cQuerylt), 'TTS', .f., .t.)
	DbSelectArea("TTS")
	DbGoTop()
	Do While !TTS->(EOF())
		_nQuantP := TTS->NQTD
		_nQTDPL	 := TTS->NPAL
		TTS->(DbSkip())
	EndDo
	TTS->(DbCloseArea())

	if _nQTDPL == 0
		if _xnTipo = 1
			rtav := AVISO("A T E N Ç Ã O...", "Não foi encontrado nenhum Palet no sistema com este nº de lote."+chr(10)+chr(13)+" Esta correto ?", { "Sim", "Não" }, 2)
		else
			rtav := AVISO("A T E N Ç Ã O...", "Não foi encontrado nenhum Bins no sistema com este nº de lote."+chr(10)+chr(13)+" Esta correto ?", { "Sim", "Não" }, 2)
		endif
		if rtav == 2
			_lRet := .F.
		else
			_nQTDPL := 1
		Endif
	else
		_nQTDPL++
	Endif
Return(_lRet)


// Efetua Consistencia do Nr.Caixas por Palet de acordo com informação do SB1                                  
Static Function _VldCx()

	Local _lRet := .T.

	/* DESABILITADO ATÉ O PREENCHIMENTO 
	_tpemb := POSICIONE('SB5', 1, xFilial('SB5') + SC2->C2_PRODUTO, 'B5_EMB2')
	_nCxs  := POSICIONE('SB5', 1, xFilial('SB5') + SC2->C2_PRODUTO, 'B5_QE2')
	IF alltrim(_tpemb) = 'PALET' .AND. (_nQtdCx) > (_nCxs+10) 
		msgalert("Quantidade de Caixas é muito superior ao Padrão")
		_lRet := .F.
	Endif
	*/

Return(_lRet)


// Efetua manutenção na tabela CB0
Static Function _PaletG(CodOP)

	Local cString := "CB0" 
	Local cFilter := "" 
	Local aCores  := {} 

	Private cCadastro := "Pallets Gerados" 
	Private aRotina   := {} 

	AADD(aCores,{"CB0_STATUS=='A' ", "VERDE" }) 						// chamado em aberto 
	AADD(aCores,{"CB0_STATUS=='E' .OR. CB0_STATUS=='P' ", "VERMELHO" }) // chamado finalizado 

	AADD(aRotina,{"Pesquisar"	,"AxPesqui", 0, 1 }) 
	AADD(aRotina,{"Visualizar"	,"AxVisual", 0, 2 }) 
	AADD(aRotina,{"Excluir"     ,"AxDeleta", 0, 5 }) 

	cFilter := "CB0_OP = '" + CodOP + "' " 

	DbSelectArea(cString) 
	DbSetOrder(1) 
				
	mBrowse( 6,1,22,75,cString,,,,,, aCores,,,,,,,,cFilter) 

Return(.T.)
