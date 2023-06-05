#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "APVT100.CH" 

/*
 Programa distripalet.prw		Data Abr/2023		Programador: Fernando Pereira
 
 Este programa faz a leitura dos dados do palet na CB0
 Pede a localização onde vai ser guardado este palet
 E faz a distribuição

*/
User Function VTCONSUM()
	Private _lRet 		:= .T.
	Private _nMaxLin 	:= 12
	Private _nMaxCol 	:= 21
	Private _cCodUsr 	:= RetCodUsr()
	Private _cNomUsr	:= UsrRetName( )
	Private _cPalet		:= Space(10)		// Nr do Palet
	Private _cLocal		:= Space(7)			// Nr do Local

	VtSetSize(_nMaxLin,_nMaxCol)

	DbSelectArea("CB1")
	DbSetorder(2)
	DbSeek(xFilial("CB1")+_cCodUsr)
	IF !Found()
		VtAlert("** OPERADOR NÃO AUTORIZADO **","ATENCAO",.T.,3000,4)
		Return()
	EndIF
	VtClear()

	// Sabe aquele programa de leitura dos palets da GRANO ? nao é esse é um dentro da pasta acd

	Do While .T.
		VtClear()
		//@ 00,00 vtSay "LEIA ETIQUETA DO PALET"
		@ 01,00 vtGet _cPalet Picture "@!" When VtLastKey() <> 27 Valid tstnpal(_cPalet)
		vtread()
		IF VtLastKey() == 27
			exit
		else
			vtClearBuffer ()
			_Tela_dp1(_cPalet)
		endIF
	EndDo
	vtClear ()
	vtClearBuffer ()
Return()

//Tela Principal de leitura
Static Function _Tela_dp1(_cPalete)
	Private _nMaxLin 	:= 12
	Private _nMaxCol 	:= 21
	Private _cEnder	    := space(10)
	Private _Volta		:= .T.
	VtClear()
	VtSetSize(_nMaxLin,_nMaxCol)

	Do While .T.
		@ 00,00 vtSay "DISTRIBUINDO PALET   : "+_cPalete
		@ 03,00 vtSay "** LEIA O ENDERECO **"
		@ 04,00 vtGet _cEnder Picture "@!" When VtLastKey() <> 27 Valid tstEnder(_cEnder)
		vtread()
		IF VtLastKey() == 27
			exit
		ELSE
			vtClearBuffer ()
            // Faz o endereçamento após passar por todas as validações
		    Enderecar(alltrim(_cPalete), alltrim(_cEnder))
		endIF
	EndDo
	VtClearBuffer()
	vtKeyBoard(chr(13))
Return(.T.)

/** 
    Função Enderecar Pega os dados da leitura da etiqueta do palet
    e do endereço e monta os dados a serem gravados 
    Faz os testes de quantidade na SDA e roda a função A100Distri()
    Se deu tudo certo retorno .T. se não mostra os erros e retorna .F.
*/
Static Function Enderecar(_cPalet, _cEnder)
	Private _lret	:= .T.
	_aArea 			:= getarea ()
	
    // Pega os dados na CB0 e na SB1 -----------------------------------------
	DbSelectArea("CB0")
	DbSetOrder(1)
	DbSeek(xFilial("CB0") + _cPalet)
	
	_cPR			:= CB0->CB0_CODPRO                  // Cod do Produto
	_cLT			:= CB0->CB0_LOTE                    // Lote do Palet
    _LocEnc		    := CB0->CB0_LOCAL                   // Local Padrão
    _nQT			:= CB0->CB0_QTDE                    // Quantidade do Palet
    
    _nConv		    := POSICIONE('SB1',  1, xFilial('SB1') + SC2->C2_PRODUTO, 'B1_CONV')
    _cSegum		    := POSICIONE('SB1',  1, xFilial('SB1') + SC2->C2_PRODUTO, 'B1_SEGUM')
    _cTipoP		    := POSICIONE('SB1',  1, xFilial('SB1') + SC2->C2_PRODUTO, 'B1_TIPO')
    // ------------------------------------------------------------------------

    // Preparando a quantidade a endereçar ------------------------------------
    if _cTipoP = 'PA' .OR. _cTipoP = 'PR'
        _nQuant	    := _nQT * _nConv
    else
        _nQuant	    := _nQT
    endif
    // ------------------------------------------------------------------------

    // Prepara o que vai ir no documento do endereçamento com informações da CB0
    _cDoc           = "Palet " + CB0->PALLET + " Etiq. " + CB0->CODETI
    // ------------------------------------------------------------------------
    
    /** Distribuindo Saldos */
    A100Distri(_cPR, _LocEnc, Nil, _cDoc, Nil, Nil, Nil, _cEnder, Space(20), _nQuant, _cLT, Nil, _cSegum)
    // ------------------------------------------------------------------------

	VTBeep()
	Restarea(_aArea)

Return(_lret)

// Testa se a OP é Inválida / Existe / Encerrada 
Static Function tstEnder(endereco)
	Local _Rto 		:= .T.
	_aArea 			:= getarea()
	IF Empty(endereco)
		VtAlert("ENDEREÇO INVÁLIDO","ATENCAO",.T.,3000,4)
		_Rto        := .F.
	EndIF
	IF _Rto
		DbSelectArea("SBE")
		DbSetOrder(1)
		DbSeek(xFilial("SBE") + endereco)
		IF !Found()
			VtAlert("ENDEREÇO NÃO EXISTENTE..","ATENCAO",.T.,3000,4)
			_Rto    := .F.
		EndIF
	EndIF
	Restarea(_aArea)
Return(_Rto)

// Teste etiqueta Inválida / Não existente / Já utilizada / Produto não pertence a ordem 
Static Function tstnpal(codeti)
	Private _Rt3 	:= .T.
	_aArea 		    := getarea ()
	codeti		    := Alltrim(codeti)

	IF Empty(codeti)
		VtAlert("CÓDIGO DE PALET INVÁLIDO", "ATENCAO", .T., 3000, 4)
		_Rt3 := .F.
	EndIF

	// Testa a etiqueta na CB0 ----------------------------------------------
	IF _Rt3
		DbSelectArea("CB0")
		DbSetOrder(1)
		DbSeek(xFilial("CB0")+codeti)
		_cProd	    := CB0->CB0_CODPRO                  // Código do Produto
        _nQT		:= CB0->CB0_QTDE                    // Quantidade do Palet
		_Filial	    := xFilial("CB0")
		
		IF !Found()
			VtAlert("ETIQUETA NÃO EXISTE", "ATENCAO", .T., 3000, 4)
			_Rt3    := .F.
		ElseIF !EMPTY(CB0->CB0_OP) .AND. EMPTY(CB0->CB0_FORNEC) .AND. CB0->CB0_STATUS<>'E'
            VtAlert("ETIQUETA AINDA NÃO PROCESSADA", "ATENCAO", .T., 3000, 4)
			_rt3    := .F.
		EndIF
	EndIF

    // TESTANDO SE HÁ AINDA SALDO A ENDEREÇAR NA SDA OK - Endereça ------------
    IF _Rt3
        _nQtdEnder  := 0
        dbSelectArea("SDA")
        dbSetOrder(1)
        dbSeek(xFilial("SDA")+_cProd)
        Do While !Eof() .And. xFilial("SDA")+_cProd == SDA->DA_FILIAL+SDA->DA_PRODUTO
            _nQtdEnder  += SDA->DA_SALDO
			SDA-> (DBSKIP())
        EndDo
        if _nQtdEnder == 0 .AND. _nQtdEnder < _nQT
            VtAlert("NÃO HÁ QUANTIDADE A ENDEREÇAR", "ATENCAO", .T., 3000, 4)
			_rt3    := .F.
		EndIF
    endIF

	Restarea(_aArea)
Return(_Rt3)
