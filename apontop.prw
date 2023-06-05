#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "RWMAKE.CH"

//--------------------------------------------------------------------------------------
/*/{Protheus.doc} APONTOP
@Type			: Função de Usuário
@Sample			: U_APONTOP()
@Description	: Rotina que aponta a OP com base em uma etiqueta CB0
@Param			: Nenhum
@Return			: Nenhum
@ --------------|-----------------------------------------------------------------------
@Author			: Evandro Mugnol
@Since			: Jan/2023
@version		: Protheus 12.1.33 e posteriores
@Comments		: Nenhum
/*/
//--------------------------------------------------------------------------------------
User Function APONTOP(_cEmpFil)

	Local TpEncer		:= "P"
	Local _lOk			:= .F.
	Local CodPA

	Private _nOP		:= space(10)
	Private _nLote		:= space(10)
	Private _dDtValid   := Ctod("")
	Private _LocPad		:= ""
	Private nTotAber	:= 0
	Private nTotEnce	:= 0
	Private cLoteCB0	:= space(10)
	Private _lVAguarde  := .F.

	Static oDlg
	Static oButton1
	Static oButton2
	Static oFont1 		:= TFont():New("Courier New",,018,,.T.,,,,,.F.,.F.)
	Static oFont2 		:= TFont():New("Open Sans",,018,,.T.,,,,,.F.,.F.)
	Static oF13 		:= TFont():New("Open Sans",,022,,.T.,,,,,.F.,.F.)
	Static oGet1
	Static oSay1

	Do While .T.
		nTotAber := 0
		nTotEnce := 0
		_nOP	 := Space(10)
		
		// Tela Principal do Programa
		DEFINE MSDIALOG oDlg TITLE "Apontamento OP UNIAGRO" FROM 000, 000  TO 160, 430 COLORS 0, 16777215 PIXEL
		
		@ 008, 005 SAY 	oSay1		PROMPT "Codigo de Barras Etiq." 	SIZE 180, 010 OF oDlg FONT oFont2 COLORS 0, 16777215 				PIXEL
		@ 006, 100 MSGET oGet1		VAR _nOP 							SIZE 075, 012 	OF oDlg COLORS 0, 16777215 FONT oFont1 								PIXEL
		
		@ 042, 004 BUTTON oButton1 	PROMPT "Processar" 		SIZE 060, 015 OF oDlg FONT oF13   ACTION (_lOk := .T.,Close(oDlg)) 	PIXEL
		@ 042, 076 BUTTON oButton2 	PROMPT "Sair" 			SIZE 060, 015 OF oDlg FONT oF13   ACTION (_lOk := .F.,Close(oDlg)) 	PIXEL
		
		ACTIVATE MSDIALOG 	oDlg

		If (!_lOk .OR. Lastkey() == 27)
			Exit
		Else
			DbSelectArea("CB0")
			DbSetOrder(1)
			If !DbSeek(xFilial("CB0") + _nOP)
				MsgAlert("Etiqueta Não Localizada")
				Loop
			Else
				If CB0->CB0_STATUS == 'E'
					MsgAlert("Etiqueta Já Apontada")
					Loop
				EndIf

				// Anota o número da OP para seguir o processo
				_cNumOP    := CB0->CB0_OP
				_nLote 	   := CB0->CB0_LOTE
				_dDtValid  := CB0->CB0_DTVLD
				_nEtiqueta := CB0->CB0_CODETI
				
				DbSelectArea("SC2")
				DbSeek(xFilial("SC2")+_cNumOP)
				If !Empty(C2_DATRF)
					MsgAlert ("Ordem de Produção Já Encerrada")
					Loop
				Else
					CodPA	 := SC2->C2_PRODUTO
					nTotPrev := (SC2->C2_QUANT)
					_nConv	 := Posicione('SB1', 1, xFilial('SB1') + SC2->C2_PRODUTO, 'B1_CONV')
					_cNomPr	 := Posicione('SB1', 1, xFilial('SB1') + SC2->C2_PRODUTO, 'B1_DESC')
					_cTipoP	 := Posicione('SB1', 1, xFilial('SB1') + SC2->C2_PRODUTO, 'B1_TIPO')
					_LocPad	 := Posicione("SB1", 1, xfilial("SB1") + SC2->C2_PRODUTO, "B1_LOCPAD")
					_lOk 	 := .F.

					// Busca Quantidades totais da ordem a encerrar Total Encerrado e Consumido de MP
					// Inicia laço para somatórios
					If _cTipoP == 'PA' .OR. _cTipoP == 'PR'
						nTotAber := CB0->CB0_QTDE * _nConv
					Else
						nTotAber := CB0->CB0_QTDE
					EndIf

					// Tipo de apontamento será sempre P parcial
					TpEncer   := 'P'
					qEncerrar := (SC2->C2_QUJE+nTotAber)
					nOpc      := Aviso( "UNIAGRO", "A t e n ç ã o.. " + Chr(10) + Chr(13) + "Será apontado Palet do Produto " +_cNomPr + chr(10) + chr(13) + "Contendo " + str(nTotAber)+" Kg", { "Cancelar","OK" }, 3 )

					If nOpc == 2
						MsAguarde({|| ApontaOP(_cNumOP, TpEncer, nTotAber, CodPA, SC2->C2_QUANT, qEncerrar, _nLote, _dDtValid, _nOP)},"Aguarde","Realizando Apontamento...",.F.)

						MsAguarde({|| EnderPRD(CodPA, nTotAber)},"Aguarde","Realizando Endereçamento do Produto...",.F.)

						MsAguarde({|| TransARM(CodPA, _nLote, _dDtValid, nTotAber)},"Aguarde","Realizando Transferência Armazém...",.F.)
					EndIf

					If !_lVAguarde
						DbSelectArea("CB0")
						RecLock ("CB0",.F.)
						CB0->CB0_USUARI := ALLTRIM(cUserName)
						MsUnLock ()
						DbSelectArea("SC2")
					EndIf
				EndIf
			EndIf
		EndIf
	EndDo

Return


// Função que aponta a OP de acordo com os dados informados acima
Static Function ApontaOP(NumOpe, TipoE, Quantid, CodProd, QTOTAL, QEnc, nLt, _dDataVld, _cNeti)

	Local aMata250	:= {}
	Local Encerrar	:= .F.

	If QEnc < QTOTAL .And. TipoE == "T"
		Tipoe 	 := "P"
		Encerrar := .T.
	EndIf

	Begin Transaction

		DbSelectArea("SC2")
		DbSetOrder(1)
		DbSeek(xFilial("SC2") + NumOpe)

		aAdd(aMata250,{"D3_FILIAL" , xFilial("SD3")					, Nil})
		aAdd(aMata250,{"D3_TM"     , "010"							, Nil})
		aAdd(aMata250,{"D3_CF"     , "PR0"    						, Nil})
		aAdd(aMata250,{"D3_GRUPO"  , SB1->B1_GRUPO    				, Nil})
		aAdd(aMata250,{"D3_OP"     , NumOpe        					, Nil})
		aAdd(aMata250,{"D3_COD"    , CodProd       					, Nil})
		aAdd(aMata250,{"D3_UM"     , SB1->B1_UM        				, Nil})
		aAdd(aMata250,{"D3_TIPO"   , SB1->B1_TIPO      				, Nil})
		aAdd(aMata250,{"D3_SEGUM"  , SB1->B1_SEGUM     				, Nil})
		aAdd(aMata250,{"D3_LOCAL"  , SC2->C2_LOCAL			 		, Nil})
		aAdd(aMata250,{"D3_EMISSAO", DDATABASE       				, Nil})
		aAdd(aMata250,{"D3_QUANT"  , Quantid   						, Nil})
		aAdd(aMata250,{"D3_QTSEGUM", ConvUM(CodProd,Quantid,0,2)	, Nil})
		aAdd(aMata250,{"D3_PARCTOT", TipoE							, Nil})
		aAdd(aMata250,{"D3_OBS"    , _cNeti                         , Nil})

		// Se o Produto é controlado por RASTRO
		If SB1->B1_RASTRO == 'L'
			aAdd(aMata250,{"D3_LOTECTL", nLt						, Nil})
			aAdd(aMata250,{"D3_DTVALID", _dDataVld 					, Nil})
		EndIf

		aMata250 := aClone(U_OrdAuto(aMata250))

		lMsHelpAuto := .F.
		lMSErroAuto := .F.
		_lVAguarde	:= .T.

		// Faz movimentacao de Producao
		msExecAuto({|x,y| MATA250(x,y)}, aMata250, 3)

		If lMSErroAuto
			MostraErro()
			DisarmTransaction()
			_lVAguarde	:= .F.
		Else
			MdSttCB0(_cNeti)
		EndIf

	End Transaction

Return


// Rotina que atualiza status da CB0
Static Function MdSttCB0(_cNumEti)

	Local _sQuery := ""

	Begin Transaction

		_sQuery := "UPDATE " + RETSQLNAME("CB0") + " "
		_sQuery += "SET CB0_STATUS = 'E' "
		_sQuery += "WHERE CB0_CODETI = '" + _cNumEti + "' AND CB0_STATUS = 'A' AND D_E_L_E_T_='' "
		TCSQLExec(_sQuery)

	End Transaction

Return


//  Função que efetua o endereçamento
Static Function EnderPRD(_cProdLoc, _nQuant)

    Local aCabSDA   := {}
    Local aItSDB    := {}
    Local aItensSDB := {}
	Local _cLocal   := ""
	Local _cDoc	 	:= ""
	Local _cNumSeq 	:= ""
	Local _cItem	:= "0001"
	Local _cLoteCtl := ""
 
    Private lMsErroAuto := .F.
 	
	// Faz isso só para pegar o registro correto no SDA. Cada um tem um NUMSEQ
	DbSelectArea("SDA")
	SDA->(DbSetOrder(1))
	SDA->(DbSeek(xFilial("SDA") + _cProdLoc))
	While !Eof() .And. SDA->DA_FILIAL + SDA->DA_PRODUTO == xFilial("SDA") + _cProdLoc
		// Se tiver saldo e for menor ou igual que quantidade digitada
		If SDA->DA_SALDO > 0 .And. _nQuant <= SDA->DA_SALDO 	//.And. SDA->DA_LOTECTL == _nLote 
			_cLocal   := SDA->DA_LOCAL
			_cLocaliz := GetAdvFVal("SBE", "BE_LOCALIZ", xFilial("SBE") + _cLocal, 1, Space(TamSx3("BE_LOCALIZ")[1]), .T.)
			_cDoc	  := SDA->DA_DOC
			_cNumSeq  := SDA->DA_NUMSEQ
			_cLoteCtl := SDA->DA_LOTECTL
			
			DbSelectArea("SDA")
			DbSkip()
		Else
			DbSelectArea("SDA")
			DbSkip()
		EndIf
	EndDo
	
	// Só para verificar qual último item, para não repetir o DB_ITEM
	DbSelectArea("SDB")
	SDB->(DbSetOrder(1))
	SDB->(DbGoTop())
	SDB->(DbSeek(xFilial("SDB") + _cProdLoc + _cNumSeq))
	While !SDB->(Eof()) .And. SDB->DB_FILIAL + SDB->DB_PRODUTO + SDB->DB_NUMSEQ == xFilial("SDB") + _cProdLoc + _cNumSeq
		_cItem := Soma1(SDB->DB_ITEM)
		DbSelectArea("SDB")
		DbSkip()
	EndDo

	If !Empty(_cNumSeq) 	// Só continua se tiver número sequencal

		// Cabecalho com a informação do item e NumSeq que será endereçado
		aCabSDA := {{"DA_PRODUTO", _cProdLoc			, Nil},;
					{"DA_LOCAL"  , _cLocal				, Nil},;
					{"DA_NUMSEQ" , _cNumSeq				, Nil},;
					{"DA_DOC" 	 , _cDoc				, Nil} }
	
		// Dados do item que será endereçado
		aItSDB :=  {{"DB_ITEM"   , _cItem      			, Nil},;
					{"DB_PRODUTO", _cProdLoc	        , Nil},;
					{"DB_LOCAL"  , _cLocal	    		, Nil},;
					{"DB_LOCALIZ", "CORREDOR"    		, Nil},;
					{"DA_DOC" 	 , _cDoc				, Nil},;
					{"DB_QUANT"  , _nQuant         		, Nil},;
					{"DB_DATA"   , dDataBase   			, Nil},;
					{"DA_LOTECTL", _cLoteCtl			, Nil},;
					{"DA_NUMSEQ" , _cNumSeq				, Nil} }

		aAdd(aItensSDB, aItSDB)
	
		BEGIN TRANSACTION

		// Executa o endereçaamento do item
		MATA265( aCabSDA, aItensSDB, 3)
		
		If lMsErroAuto
			MostraErro()
			DISARMTRANSACTION()
		EndIf

		END TRANSACTION

	EndIf

Return


//  Função que efetua a transferência múltipla
Static Function TransARM(_cProd,_cNumLote,_dDataVld,_nQtde)

	Local aAuto 	:= {}
	Local aItem 	:= {}
	Local aLinha 	:= {}
	Local nOpcAuto 	:= 0
	Local cDocumen 	:= ""

	Private lMsErroAuto := .F.

	//Cabecalho a Incluir
	cDocumen := GetSxeNum("SD3","D3_DOC")
	aAdd(aAuto,{cDocumen,dDataBase})

	//Itens a Incluir
	aItem  := {}
    aLinha := {}
 
    // Origem
    SB1->(DbSeek(xFilial("SB1") + _cProd))
    aAdd(aLinha,{"ITEM",	   "0001"					, Nil})
	aAdd(aLinha,{"D3_COD",     SB1->B1_COD				, Nil}) // Codigo Produto origem
    aAdd(aLinha,{"D3_DESCRI",  SB1->B1_DESC				, Nil}) // Descrição Produto origem
    aAdd(aLinha,{"D3_UM", 	   SB1->B1_UM				, Nil}) // Unidade Medida origem
    aAdd(aLinha,{"D3_LOCAL",   "PRO"					, Nil}) // Armazem origem
    aAdd(aLinha,{"D3_LOCALIZ", "CORREDOR"				, Nil}) // Localização Origem  
    
	// Destino
    aAdd(aLinha,{"D3_COD", 	   SB1->B1_COD				, Nil}) // Codigo Produto destino
    aAdd(aLinha,{"D3_DESCRI",  SB1->B1_DESC				, Nil}) // Descrição Produto destino
    aAdd(aLinha,{"D3_UM", 	   SB1->B1_UM				, Nil}) // Unidade Medida destino
    aAdd(aLinha,{"D3_LOCAL",   "DEP"					, Nil}) // Armazem destino
    aAdd(aLinha,{"D3_LOCALIZ", ""						, Nil}) // Localização Destino  
    
  	aAdd(aLinha,{"D3_NUMSERI", ""						, Nil}) // Numero serie
  	
	If SB1->B1_RASTRO == 'L'
		aAdd(aLinha,{"D3_LOTECTL", _nLote				, Nil}) // Lote Origem
		aAdd(aLinha,{"D3_NUMLOTE", ""					, Nil}) // Sublote Origem
		aAdd(aLinha,{"D3_DTVALID", _dDataVld			, Nil}) // Data Validade Origem
	EndIf

 	aAdd(aLinha,{"D3_POTENCI", 0						, Nil}) // Potencia
    aAdd(aLinha,{"D3_QUANT",   _nQtde					, Nil}) // Quantidade
    aAdd(aLinha,{"D3_QTSEGUM", ConvUM(SB1->B1_COD,_nQtde,0,2), Nil}) // Seg unidade medida
    aAdd(aLinha,{"D3_ESTORNO", ""						, Nil}) // Estorno
    aAdd(aLinha,{"D3_NUMSEQ",  ""						, Nil}) // Numero Sequencia
    
	If SB1->B1_RASTRO == 'L'
		aAdd(aLinha,{"D3_LOTECTL", _nLote				, Nil}) // Lote Destiono
		aAdd(aLinha,{"D3_NUMLOTE", ""					, Nil}) // Sublote Destino
		aAdd(aLinha,{"D3_DTVALID", _dDataVld			, Nil}) // Data Validade Destino
	EndIf

    aAdd(aLinha,{"D3_ITEMGRD", ""						, Nil}) // Item Grade
    aAdd(aLinha,{"D3_CODLAN",  ""						, Nil}) // Cat83 Prod Origem
    aAdd(aLinha,{"D3_CODLAN",  ""						, Nil}) // Cat83 Prod Destino

    aAdd(aAuto,aLinha)

	nOpcAuto := 3 // Inclusao
	MSExecAuto({|x,y| mata261(x,y)},aAuto,nOpcAuto)

	If lMsErroAuto
		MostraErro()
	EndIf

Return
