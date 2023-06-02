#include "totvs.ch"
#include "RESTFUL.ch"
#include "topconn.ch"
/*
+-----------+-----------+-------+-------------------------------------+------+----------+
| Funcao    | PUTSTATUS | Autor | Manoel M Mariante                 | Data |11/2021   |
|-----------+-----------+-------+-------------------------------------+------+----------|
| Descricao | API POST para atualizaçao do status de integraçao do pedido               |
|           |                                                                           |
|           |                                                                           |
|-----------+---------------------------------------------------------------------------|
| Sintaxe   | executado via menu                                                        |
+-----------+---------------------------------------------------------------------------+
*/
WSRESTFUL PUTSTATUS DESCRIPTION "Status do Pedido de Venda"

	WSMETHOD POST DESCRIPTION "Atualizar o Status do Pedido" WSSYNTAX "/"

END WSRESTFUL

//--------------------------------------------------------------------------------------------
WSMETHOD POST WSRECEIVE NULLPARAM WSSERVICE PUTSTATUS
//--------------------------------------------------------------------------------------------

	Local lOk		:= .T., nP
	Local cBody		:= ::GetContent()
	Local oJson
	Local cRetBody	:='{"code":"","message":""}'
	Local aItensSC6	:={}

	::SetContentType("application/json")//Define o tipo de retorno do metodo

	If !FWJsonDeserialize(cBody,@oJson)//Converte a estrutura Json em Objeto
		SetRestFault( 101, "Nao foi possivel processar a estrutura Json." )
		Return .f.
	End
	IF At('C5_NUM',upper(cBody))=0 //=NIL
		SetRestFault( 109, "Pedido Nao Informado" )
		conout("UNIA015 - Tabela nao informada")
		Return .f.
	End
	IF At('PRODUCTS',upper(cBody))=0 //=NIL
		SetRestFault( 112, "objeto 'products' Nao Informados" )
		conout("UNIA015 - objeto 'products' nao informada")
		Return .f.
	End

	cPedido:=oJson:c5_num

	DbSelectArea('SC5')
	DbSetOrder(1)
	IF !dbSeek(xFilial('SC5')+cPedido)
		SetRestFault( 110, "Pedido Nao Encontrado" )
		conout("UNIA015 - Pedido nao encontrado")
		Return .f.
	End

	If At('C5_SITWMS',upper(cBody))=0 //=NIL empty(oJson:c5_sitwms)
		SetRestFault( 115, "Status Nao informado" )
		conout("UNIA015 - Script Nao informado")
		Return .f.
	End
	
	cStatus:=oJson:c5_sitwms

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
	/*
	If cStatus < '10'
		SetRestFault( 120, "Codigo de Status nao Aceito no pedido. Aceitos somente igual ou superiores a 10 " )
		conout("UNIA015 - Código de Status nao Aceito no pedido. Aceito igual ou superiores a '10'")
		Return .f.
	End
	*/
	/*
	If SC5->C5_SITWMS < '05'
		SetRestFault( 121, "Codigo de Status nao Aceito no pedido. Atual "+SC5->C5_SITWMS )
		conout("UNIA015 - Código de Status nao Aceito no pedido")
		Return .f.
	End
	*/

	For nP:=1 to Len(oJson['products'])

		cProduto:=PADR(oJson['products'][nP]['C6_PRODUTO'],TamSX3('C6_PRODUTO')[1])
		nQtdEmp	:=oJson['products'][nP]['C6_EMPWMS']

		IF aScan(aItensSC6,{|x|  x[3] == cProduto })
			SetRestFault( 124, "Produto ja enviado anteriormente nesse JSON: "+cProduto )
			conout("UNIA020 - Produto ja enviado anteriormente nesse JSON: "+cProduto)
			Return .f.
		end

		DbSelectArea('SC6')
		DbSetOrder(2)
		IF !dbSeek(xFilial('SC6')+cProduto+cPedido)
			SetRestFault( 110, "Produto Nao Encontrado no Pedido. Produto="+cProduto )
			conout("UNIA020 - Produto Nao Encontrado no Pedido")
			Return .f.
		End

		If SC6->C6_LIBWMS == 0
			SetRestFault( 140, "Produto Sem Liberacao para o WMS. Produto="+cProduto )
			conout("UNIA020 - Produto Sem Liberacao para o WMS"+cProduto)
			Return .f.
		End

		If nQtdEmp > SC6->C6_LIBWMS 
			SetRestFault( 141, "Quantidade enviada no Status maior que a Quantidade Liberada para o WMS.Produto = "+cProduto )
			conout("UNIA020 - Quantidade enviada no Status maior que a Quantidade Liberada para o WMS "+cProduto)
			Return .f.
		End

		Aadd(aItensSC6,{SC6->(RECNO()),nQtdEmp,cProduto} )

	Next

	If lOk
		RecLock('SC5', .f.)
		SC5->C5_SITWMS:=cStatus
		SC5->C5_ESPECI1 := cEspeci1
		SC5->C5_ESPECI2 := cEspeci2
		SC5->C5_ESPECI3 := cEspeci3
		SC5->C5_VOLUME1 := nVolume1
		SC5->C5_VOLUME2 := nVolume2
		SC5->C5_VOLUME3 := nVolume3
		MsUnlock()

		DbSelectArea('SC6')
		For nP:=1 To Len(aItensSC6)
			dbGoto(aItensSC6[nP,1])
			RecLock('SC6', .f.)
			SC6->C6_LIBWMS := SC6->C6_LIBWMS - aItensSC6[nP,2]
			SC6->C6_EMPWMS := SC6->C6_EMPWMS + aItensSC6[nP,2]
			ConOut('UNIA015 - Atualizei C6_EMPWMS/C6_LIBWMS produto '+SC6->C6_PRODUTO + ' quantidade '+CValToChar(aItensSC6[nP,2]))
			MsUnlock()
		NExt
		cRetBody:='{"code":"010","message":"Sucesso no envio"}'
	endif

	::SetResponse(cRetBody)

Return( lOk )

