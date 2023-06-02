#include "totvs.ch"
#include "RESTFUL.ch"
#include "topconn.ch"
/*
+-----------+-----------+-------+-------------------------------------+------+----------+
| Funcao    | COLLECTEDPROD | Autor | Manoel M Mariante                 | Data |11/2021   |
|-----------+-----------+-------+-------------------------------------+------+----------|
| Descricao | API POST para atualizaçao do status de integraçao do pedido               |
|           |                                                                           |
|           |                                                                           |
|-----------+---------------------------------------------------------------------------|
| Sintaxe   | executado via menu                                                        |
+-----------+---------------------------------------------------------------------------+
*/
WSRESTFUL COLLECTEDPROD DESCRIPTION "Produtos Coletados do Pedido de Venda"

	WSMETHOD POST DESCRIPTION "Atualizar os Produtos Coletados do Pedido" WSSYNTAX "/"

END WSRESTFUL

//--------------------------------------------------------------------------------------------
WSMETHOD POST WSRECEIVE NULLPARAM WSSERVICE COLLECTEDPROD
//--------------------------------------------------------------------------------------------

	Local lOk		:= .T.
	Local cBody		:= ::GetContent()
	Local oJson
	Local cRetBody	:='{"code":"010","message":"Sucesso no envio"}'
	Local nP,nK
	Local aLotes	:={}
	Local aProds	:={}
	Local _XPOSQTD	:=1
	Local _XPOSPRO	:=2
	Local _XPOSLOT	:=3
	Local _XPOSVAL	:=4
	Local _XPOSREC	:=5
	Local cTab		:='SC9'

	Private cOrdSep:=''
	Private aCampos	:={} //'C9_FILIAL','C9_PEDIDO','C9_ITEM','C9_PRODUTO','C9_CLIENTE','C9_LOJA','C9_QTDLIB'}
	Private _CRLF	:=CHR(13)+CHR(10)

	dbSelectArea("SX3")
	dbSetOrder(1)
	dbSeek(cTab)

	While !Eof() .And. (x3_arquivo == cTab)
		if x3_context=='V'
			DBSKIP()
			loop
		end
		aADD(aCampos,alltrim(x3_campo))
		DBSKIP()
	eND

	::SetContentType("application/json")//Define o tipo de retorno do metodo

	If !FWJsonDeserialize(cBody,@oJson)//Converte a estrutura Json em Objeto
		SetRestFault( 101, "Nao foi possivel processar a estrutura Json." )
		u_FWLogIntef(/*cRot*/ 'UNIA020',/*cPed*/ '',/*cJson*/ '',/*cProd*/ '',/*cLote*/ '',/*cDesc*/"Nao foi possivel processar a estrutura Json." )
		Return .f.
	End
	IF At('C5_NUM',upper(cBody))=0 //=NIL
		SetRestFault( 109, "Pedido Nao Informado" )
		//conout("UNIA020 - Tabela nao informada")
		u_FWLogIntef(/*cRot*/ 'UNIA020',/*cPed*/ '',/*cJson*/ cBody,/*cProd*/ '',/*cLote*/ '',/*cDesc*/"Pedido Nao Informado" )
		Return .f.
	End

	IF At('ORDEM_SEPARACAO',upper(cBody))<>0 //=NIL
		//SetRestFault( 109, "Pedido Nao Informado" )
		//conout("UNIA020 - Tabela nao informada")
		//Return .f.
		cOrdSep:=PADR(oJson:ORDEM_SEPARACAO,TamSX3('C9_OSWMS')[1])
	End

	cPedido:=PADR(oJson:c5_num,TamSX3('C5_NUM')[1])
	DbSelectArea('SC5')
	DbSetOrder(1)
	IF !dbSeek(xFilial('SC5')+cPedido)
		SetRestFault( 110, "Pedido Nao Encontrado" )

		u_FWLogIntef(/*cRot*/ 'UNIA020',/*cPed*/ cPedido,/*cJson*/ cBody,/*cProd*/ '',/*cLote*/ '',/*cDesc*/"Pedido Nao Encontrado" )

		//conout("UNIA020 - Pedido nao encontrado")
		Return .f.
	End

	cStatus:=SC5->C5_SITWMS

	cEspeci1:=''
	cEspeci2:=''
	cEspeci3:=''
	nVolume1:=0
	nVolume2:=0
	nVolume3:=0
	IF At('C5_ESPECI1',upper(cBody))<>0 //=NIL
		cEspeci1:=PADR(oJson:C5_ESPECI1,TamSX3('C5_ESPECI1')[1])
	end
	IF At('C5_ESPECI2',upper(cBody))<>0 //=NIL
		cEspeci2:=PADR(oJson:C5_ESPECI2,TamSX3('C5_ESPECI2')[1])
	end
	IF At('C5_ESPECI3',upper(cBody))<>0 //=NIL
		cEspeci3:=PADR(oJson:C5_ESPECI3,TamSX3('C5_ESPECI3')[1])
	end
	IF At('C5_VOLUME1',upper(cBody))<>0 //=NIL
		nVolume1:=oJson:C5_VOLUME1
	end
	IF At('C5_VOLUME2',upper(cBody))<>0 //=NIL
		nVolume2:=oJson:C5_VOLUME2
	end
	IF At('C5_VOLUME3',upper(cBody))<>0 //=NIL
		nVolume3:=oJson:C5_VOLUME3
	end

	IF At('C6_PRODUTO',upper(cBody))=0 //=NIL
		SetRestFault( 114, "Produto Nao Informado" )
		//conout("UNIA020 - Produto nao informado")
		u_FWLogIntef(/*cRot*/ 'UNIA020',/*cPed*/ cPedido,/*cJson*/ cBody,/*cProd*/ '',/*cLote*/ '',/*cDesc*/"Produto Nao Informado" )
		Return .f.
	End

	IF At('PRODUCTS',upper(cBody))=0 //=NIL
		SetRestFault( 115, "objeto 'products' Nao Informado" )
		u_FWLogIntef(/*cRot*/ 'UNIA020',/*cPed*/ cPedido,/*cJson*/ cBody,/*cProd*/ '',/*cLote*/ '',/*cDesc*/"objeto 'products' Nao Informado")
		//conout("UNIA020 - objeto 'products' Nao Informado")
		Return .f.
	End

	For nP:=1 to Len(oJson['products'])

		cProduto:=PADR(oJson['products'][nP]['C6_PRODUTO'],TamSX3('C6_PRODUTO')[1])
		nQtdVen	:=oJson['products'][nP]['C6_QUANT']
		cLoteCtl:=PADR(oJson['products'][nP]['C6_LOTE'],TamSX3('B8_LOTECTL')[1])

		DbSelectArea('SC6')
		DbSetOrder(2)
		IF !dbSeek(xFilial('SC6')+cProduto+cPedido)
			SetRestFault( 117, "Produto Nao Encontrado no Pedido. "+cProduto )
			u_FWLogIntef(/*cRot*/ 'UNIA020',/*cPed*/ cPedido,/*cJson*/ cBody,/*cProd*/ cProduto,/*cLote*/ '',/*cDesc*/"Produto Nao Encontrado no Pedido. "+cProduto )			
			//conout("UNIA020 - Produto Nao Encontrado no Pedido")
			Return .f.
		End

		DbSelectArea('SB8')
		DbSetOrder(5)
		IF !dbSeek(xFilial('SB8')+cProduto+cLoteCtl)
			SetRestFault( 135, "Lote Nao Encontrado. "+cLoteCtl )
			u_FWLogIntef(/*cRot*/ 'UNIA020',/*cPed*/ cPedido,/*cJson*/ cBody,/*cProd*/ cProduto,/*cLote*/ cLoteCtl,/*cDesc*/"Lote Nao Encontrado. "+cLoteCtl )	
			//conout("UNIA020 - Lote Nao Encontrado "+cLoteCtl)
			Return .f.
		End

		//---lotes -------------------------//
		nPos:=aScan( aLotes,{|x| x[_XPOSPRO]+x[_XPOSLOT] == cProduto+cLoteCtl } )
		iF nPos==0
			Aadd(aLotes,array(10))
			nPos1:=Len(aLotes)
			aLotes[nPos1,_XPOSPRO]:=cProduto
			aLotes[nPos1,_XPOSQTD]:=nQtdVen
			aLotes[nPos1,_XPOSLOT]:=cLoteCtl
			aLotes[nPos1,_XPOSVAL]:=SB8->B8_DTVALID
			aLotes[nPos1,_XPOSREC]:=SC6->(RECNO())

		else
			aLotes[nPos,_XPOSQTD]:=aLotes[nPos,_XPOSQTD]+nQtdVen
		end

		//-------produtos ---//
		nPos:=aScan( aProds,{|x| x[_XPOSPRO] == cProduto } )
		iF nPos==0
			Aadd(aProds,array(10))
			nPos1:=Len(aProds)
			aProds[nPos1,_XPOSPRO]:=cProduto
			aProds[nPos1,_XPOSQTD]:=nQtdVen
			aProds[nPos1,_XPOSREC]:=SC6->(RECNO())
		else
			aProds[nPos,_XPOSQTD]:=aProds[nPos,_XPOSQTD]+nQtdVen
		end

	next

	aLotes      := ASort(aLotes,,,     { |x,y| x[_XPOSPRO]>y[_XPOSPRO] })

	//AVALIAÇÃO DOS LOTES--------------------------
	For nP:=1 to Len(aLotes)

		DbSelectArea('SB8')
		DbSetOrder(3)
		dbSeek(xFilial('SB8')+aLotes[nP,_XPOSPRO]+SC6->C6_LOCAL+aLotes[nP,_XPOSLOT])
		IF (SB8->B8_SALDO - SB8->B8_EMPENHO) < aLotes[nP,_XPOSQTD]
			SetRestFault( 136, "Lote Nao Possui Saldo. Produto "+aLotes[nP,_XPOSPRO]+" Lote "+aLotes[nP,_XPOSLOT])
			u_FWLogIntef(/*cRot*/ 'UNIA020',/*cPed*/ cPedido,/*cJson*/ cBody,/*cProd*/ aLotes[nP,_XPOSPRO],/*cLote*/ aLotes[nP,_XPOSLOT],/*cDesc*/"Lote Nao Possui Saldo. "+aLotes[nP,_XPOSPRO]+" Lote "+aLotes[nP,_XPOSLOT]+' Saldo '+CValToChar(SB8->B8_SALDO - SB8->B8_EMPENHO)+' Quant '+CValToChar(aLotes[nP,_XPOSQTD]) )
			//conout("UNIA020 - Lote Nao Possui Saldo. "+aLotes[nP,_XPOSPRO])
			Return .f.
		End
	next

	//AVALIAÇÃO DOS PRODUTOS--------------------------
	For nP:=1 to Len(aProds)

		DbSelectArea('SC6')
		dbGoTo(aProds[nP,_XPOSREC])

		dbSelectarea('SB2')
		dbSetorder(1)
		dbSeek(xFilial('SB2')+aProds[nP,_XPOSPRO]+SC6->C6_LOCAL)
		nSaldoSB2:=SaldoSB2()
		IF nSaldoSB2 < aProds[nP,_XPOSQTD]
			SetRestFault( 137, "Quantidade coletado maior que o saldo disponível no ERP ="+aProds[nP,_XPOSPRO] +'. Coletado = '+CValToChar(aProds[nP,_XPOSQTD])+', disponivel ='+CValToChar(nSaldoSB2))
			u_FWLogIntef(/*cRot*/ 'UNIA020',/*cPed*/ cPedido,/*cJson*/ cBody,/*cProd*/ aProds[nP,_XPOSPRO],/*cLote*/ '',/*cDesc*/ "Quantidade coletado maior que o saldo disponível ="+aProds[nP,_XPOSPRO] +'.Coletado = '+CValToChar(aProds[nP,_XPOSQTD])+',Disponivel ='+CValToChar(nSaldoSB2) )

			//conout("UNIA020 - Quantidade coletado maior que o saldo disponível no ERP ="+aProds[nP,_XPOSPRO] +'. Coletado = '+CValToChar(aProds[nP,_XPOSQTD])+', disponivel ='+CValToChar(nSaldoSB2))
			Return .f.
		end

		If aProds[nP,_XPOSQTD] > SC6->C6_EMPWMS
			SetRestFault( 138, "Quantidade enviada maior que o Empenhada no Envio do Status.Produto = "+aProds[nP,_XPOSPRO] +'  Quant Empenhado:'+CValToChar(SC6->C6_EMPWMS ))
			u_FWLogIntef(/*cRot*/ 'UNIA020',/*cPed*/ cPedido,/*cJson*/ cBody,/*cProd*/ aProds[nP,_XPOSPRO],/*cLote*/ '',/*cDesc*/ "Quantidade enviada maior que o Empenhada no Envio do Status.Produto = "+aProds[nP,_XPOSPRO] +'  Quant Empenhado:'+CValToChar(SC6->C6_EMPWMS ) )

			//conout("UNIA020 - Quantidade enviada no Status maior que a Quantidade Empenhada no Envio do Status.Produto = "+aProds[nP,_XPOSPRO] +'  Quant:'+CValToChar(aProds[nP,_XPOSQTD] ))
			Return .f.
		End

	next

	// -- tudo  ok, vou começar a gravação -----------------

	DbSelectArea('SC5')
	RecLock('SC5', .F.)
	SC5->C5_ESPECI1 := cEspeci1
	SC5->C5_ESPECI2 := cEspeci2
	SC5->C5_ESPECI3 := cEspeci3
	SC5->C5_VOLUME1 := nVolume1
	SC5->C5_VOLUME2 := nVolume2
	SC5->C5_VOLUME3 := nVolume3
	MsUnlock()

	//aqui vou deletar o SC9 que estiver bloqueado e nao faturado. depois vou recriar com o que sobrar do pedido
	//o conceito eh ter sempre o pedido liberado 100% comercialmente
	DbSelectArea('SC9')
	DbSetOrder(1)
	dbSeek(xFilial('SC9')+cPedido,.T.)
	While C9_FILIAL+C9_PEDIDO == xFilial('SC9')+cPedido .and. !EOF()

		IF EMPTY(SC9->C9_BLEST).OR.!Empty(SC9->C9_LOTECTL) //ja está liberado anteriormente e não posso mexer mais
			SC9->(DBSKIP())
			loop
		END
		IF SC9->C9_BLEST=='10' //ja faturado
			SC9->(DBSKIP())
			loop
		END

		DbSelectArea('SC9')
		RecLock('SC9', .f.)
		dbDelete()
		MsUnlock()

		DBSKIP()
	End

	//GRAVANDO A LIBERAÇÃO COMERCIAL COM LOTES INFORMADOS -----------------/

	For nK:=1 to Len(aLotes)

		DbSelectArea('SC6')
		dbGoTo(aLotes[nK,_XPOSREC])

		RecLock('SC9', .t.)

		fGravaSC9()

		SC9->C9_QTDLIB	:=aLotes[Nk,_XPOSQTD]
		SC9->C9_LOTECTL	:=aLotes[Nk,_XPOSLOT]
		SC9->C9_DTVALID	:=aLotes[Nk,_XPOSVAL]
		SC9->C9_OSWMS	:=cOrdSep

		MsUnlock()

		DbSelectArea('SB8')
		DbSetOrder(5)
		dbSeek(xFilial('SB8')+aLotes[nK,_XPOSPRO]+aLotes[nK,_XPOSLOT])
		RecLock('SB8', .F.)
		SB8->B8_EMPENHO:=SB8->B8_EMPENHO + aLotes[nK,_XPOSQTD]
		MsUnlock()

		RecLock('SC6', .f.)
		SC6->C6_QTDLIB:=SC6->C6_QTDLIB + aLotes[nK,_XPOSQTD]
		SC6->C6_EMPWMS:=SC6->C6_EMPWMS - aLotes[nK,_XPOSQTD]
		msunlock()

		DbSelectArea('SB2')
		DbSetOrder(1)
		dbSeek(xFilial('SB2')+SC6->C6_PRODUTO+SC6->C6_LOCAL)
		RecLock('SB2', .F.)
		SB2->B2_RESERVA:=SB2->B2_RESERVA + aLotes[nK,_XPOSQTD]
		MsUnlock()

		u_FWLogIntef(/*cRot*/ 'UNIA020',/*cPed*/ cPedido,/*cJson*/ cBody,/*cProd*/ aLotes[nK,_XPOSPRO],/*cLote*/ aLotes[nK,_XPOSLOT],/*cDesc*/ "Lote reservado com sucesso.")


	Next

	//agora vou recriar a SC9 com as qtd que ainda não foram separas e preciso manter a SC9 bloqueada por estoque----------//

	For nP:=1 to Len(aProds)

		DbSelectArea('SC6')
		dbGoTo(aProds[nP,_XPOSREC])

		nJaLib	:=fJaLibSC9(SC6->C6_NUM,SC6->C6_ITEM,SC6->C6_PRODUTO)
		nQtdLIB:=SC6->C6_QTDEMP - nJaLib

		IF nQtdLib <= 0 //alterado em 24/02
			Loop
		EndIf
		
		RecLock('SC9', .t.)

		fGravaSC9() //inicializa com os campos que não irão variar
		
		SC9->C9_QTDLIB	:=nQtdLIB
		SC9->C9_BLEST	:='02'

		MsUnlock()

	Next



	::SetResponse(cRetBody)

Return( lOk )


//---------------------------------------------------------
Static Function fPrxSeqSC9(cPedido,cItem,cProduto)
//--------------------------------------------------------
	Local cSeq		:='00'
	Local cQuery	:=''
	Local aArea  	:=GetArea()

	cQuery := " SELECT MAX(C9_SEQUEN) C9_SEQUEN "+_CRLF
	cQuery += " FROM " + RetSqlTab("SC9") +_CRLF
	cQuery += " WHERE " + RetSqlDel("SC9") +_CRLF
	cQuery += " AND " + RetSqlFil("SC9") +_CRLF
	cQuery += " AND C9_PEDIDO='"+cPedido+"' "+_CRLF
	cQuery += " AND C9_ITEM='"+cItem+"' "+_CRLF
	cQuery += " AND C9_PRODUTO='"+cProduto+"' "+_CRLF

	dbUseArea( .T.,"TOPCONN", TCGENQRY(,,cQuery),"TRX", .F., .T.)

	IF !EOF()
		cSeq:=TRX->C9_SEQUEN
	END
	cSeq:=soma1(cSeq)

	DbSelectArea('TRX')
	DBCLOSEAREA()

	RestArea(aArea)
Return cSeq


//---------------------------------------------------------
Static Function fJaLibSC9(cPedido,cItem,cProduto)
//--------------------------------------------------------
	Local nRet		:=0
	Local cQuery	:=''
	Local aArea  	:=GetArea()

	cQuery := " SELECT SUM(C9_QTDLIB) C9_QTDLIB "+_CRLF
	cQuery += " FROM " + RetSqlTab("SC9") +_CRLF
	cQuery += " WHERE " + RetSqlDel("SC9") +_CRLF
	cQuery += " AND " + RetSqlFil("SC9") +_CRLF
	cQuery += " AND C9_PEDIDO='"+cPedido+"' "+_CRLF
	cQuery += " AND C9_ITEM='"+cItem+"' "+_CRLF
	cQuery += " AND C9_PRODUTO='"+cProduto+"' "+_CRLF
	cQuery += " AND C9_BLEST='  ' "+_CRLF

	dbUseArea( .T.,"TOPCONN", TCGENQRY(,,cQuery),"TRX", .F., .T.)

	IF !EOF()
		nRet:=TRX->C9_QTDLIB
	END

	DbSelectArea('TRX')
	DBCLOSEAREA()

	RestArea(aArea)
Return nRet

//---------------------------------------------------------
//carrega a SC9 com os campos default 
Static Function fGravaSC9()
//----------------------------------------------
	Local nSX3:=0
	For nSX3:=1 to Len(aCampos)
		cCampo:='SC9->'+aCampos[nSX3]
		cContent:=CriaVar(aCampos[nSX3])
		&(ccampo):=cContent
	Next

	cSequen:=fPrxSeqSC9(SC6->C6_NUM,SC6->C6_ITEM,SC6->C6_PRODUTO)

	SC9->C9_FILIAL	:=xFilial('SC9')
	SC9->C9_PEDIDO	:=SC6->C6_NUM
	SC9->C9_ITEM	:=SC6->C6_ITEM
	SC9->C9_PRODUTO	:=SC6->C6_PRODUTO //aLotes[Nk,_XPOSPRO]
	SC9->C9_LOCAL	:=SC6->C6_LOCAL
	SC9->C9_PRCVEN	:=SC6->C6_PRCVEN
	SC9->C9_GRUPO	:=pOSICIONE('SB1',1,xFilial('SB1')+SC6->C6_PRODUTO,'B1_GRUPO')
	SC9->C9_DATENT	:=SC6->C6_ENTREG
	SC9->C9_TPCARGA	:=SC5->C5_TPCARGA 
	SC9->C9_CLIENTE	:=SC5->C5_CLIENTE 
	SC9->C9_LOJA	:=SC5->C5_LOJACLI 
	SC9->C9_SEQUEN	:=cSequen
	//SC9->C9_QTDLIB	:=aLotes[Nk,_XPOSQTD]
	//SC9->C9_LOTECTL	:=aLotes[Nk,_XPOSLOT]
	//SC9->C9_DTVALID	:=aLotes[Nk,_XPOSVAL]

Return

User Function FWLogIntef(cRot,cPed,cJson,cProd,cLote,cDesc)
	Local aArea:=GetArea()
	If !SuperGetMV('ES_LOGWMS',.f.,.t.)
		Return 
	End
	dbSelectArea("SZ9")
	RecLock("SZ9",.t.)
	SZ9->Z9_FILIAL		:=xFilial('SZ9')
	SZ9->Z9_USER		:=alltrim(Substr(cUsuario,7,15))
	SZ9->Z9_DATA  		:=msDate()
	SZ9->Z9_HORA  		:=time()
	SZ9->Z9_ROTINA		:=cRot
	SZ9->Z9_PEDIDO 		:=cPed
	SZ9->Z9_JSON   		:=cJson
	SZ9->Z9_COD 		:=cProd
	SZ9->Z9_LOTECTL		:=cLote
	SZ9->Z9_MESSAGE		:=cDesc
	msunlock()
	RestArea(aArea)

Return

