#include "totvs.ch"
#include "RESTFUL.ch"
#include "topconn.ch"
/*
+-----------+-----------+-------+-----------------------------------------------------------------------------------+------+----------+
| Funcao    | TAKEORDER | Autor | Manoel M Mariante                                                                 | Data |11/2021   |
|-----------+-----------+-------+-----------------------------------------------------------------------------------+------+----------|
| Descricao | API GET PARA RETORNAR OS PEDIDOS                                                                                        |
|           |                                                                                                                         |
|-----------+-------------------------------------------------------------------------------------------------------------------------|
| Sintaxe   | executado via menu                                                                                                      |
+-----------+-------------------------------------------------------------------------------------------------------------------------+
*/
WSRESTFUL TAKEORDER DESCRIPTION "Pedidos de Venda"

	WSDATA c5_num AS STRING
	WSDATA c5_sitwms AS STRING

	WSMETHOD GET DESCRIPTION "Lista as linhas de tabelas do Protheus" WSSYNTAX "/"
	WSMETHOD PUT DESCRIPTION "Marcar linhas da tabelas do Protheus como Integrados" WSSYNTAX "/"

END WSRESTFUL


//----------------------------------------------------------------------------------------------
WSMETHOD GET WSRECEIVE C5_NUM,C5_SITWMS WSSERVICE TAKEORDER
//----------------------------------------------------------------------------------------------

	Local lOk 		:= .T.
	Local cQuery    :=cQuery2:=''
	Local cOrder	:=''
	Local nL		:=0

	conout('1')

	PRIVATE aHeader 	:= {} //cabec do JSON
	Private cVersion	:='2.03 27/01/2022'

	// Define o tipo de retorno do metodo
	::SetContentType("application/json")

	_orders     :=LoadHead() //{'C5_NUM','C5_EMISSAO','A1_NOME'}
	_produtcs   :=loadItems() // {'B1_DESC','C6_PRODUTO','C6_TES'}

	conout('2')

	cQuery += " SELECT SC5.*, SA1.*,ISNULL(A4_NOME,'') A4_NOME, ISNULL(A4_CGC,'') A4_CGC "
	cQuery += " FROM "+RetSqlTab("SA1,SC5")
	cQuery += " LEFT JOIN "+RetSqlName("SA4")+" ON "
	cQuery += RetSqlName("SA4")+".D_E_L_E_T_=' ' "
	cQuery += " AND "+RetSqlFil("SA4")
	cQuery += " AND A4_COD=C5_TRANSP"
	cQuery += " WHERE "+RetSqlFil("SC5,SA1")
	cQuery += " AND "+RetSqlDEL("SC5,SA1")
	cQuery += " AND C5_CLIENTE = A1_COD "
	cQuery += " AND C5_LOJACLI = A1_LOJA "
	//cQuery += " AND C5_SITWMS<>'00'"
	cQuery += " AND (SELECT COUNT(*) FROM "+RetSqlTab("SC9")+" WHERE "+RetSqlFil("SC9")+" AND "+RetSqlDEL("SC9")
	cQuery += " AND C9_PEDIDO=C5_NUM AND C9_BLCRED=' ' AND C9_BLEST<>'  ' AND C9_BLEST<>'10') > 0"
	//somente os pedidos que tem saldo liberado para integra��o
	cQuery += " AND (SELECT COUNT(*) FROM "+RetSqlTab("SC6")+" WHERE "+RetSqlFil("SC6")+" AND "+RetSqlDEL("SC6")
	cQuery += " AND C6_NUM=C5_NUM AND C6_LIBWMS<>0) > 0"
	If !Empty( ::C5_NUM )
		cQuery += " AND C5_NUM='"+::C5_NUM+"' "
	END
	If !Empty( ::C5_SITWMS )
		cQuery += " AND C5_SITWMS='"+::C5_SITWMS+"' "
	END

	cQuery += " ORDER BY C5_NUM "

	cQuery := ChangeQuery(cQuery)

	TCQuery cQuery New Alias "QRYC"
	conout(cQuery)

	dbGoTop()

	conout('3')

	memowrit('c:\temp\TAKEORDER.txt',cQuery)

	oOrders:=JsonObject():new()
	oOrders['orders']:={}

	//Percorre todos os registros da query
	dbSelectArea("QRYC")
	DbGoTop()
	While ! EoF()

		oCabec:=JsonObject():new()
		For nL:=1 to len(_orders)
			IF valtype(_orders[nL])=='C'
				cTagName:=_orders[nL]
				cContent:=&('QRYC->'+_orders[nL])

			elseif valtype(_orders[nL])=='A'
				cTagName:=_orders[nL,2]
				cContent:=&('QRYC->'+_orders[nL,1])
			else
				loop
			end

			oCabec[cTagName]		:=CValToChar(cContent)
		Next
		oCabec['version']		:=cVersion

		oCabec['products']		:={}

		cQuery2 := " SELECT SC6.*, SB1.*, SC9.* "
		cQuery2 += " FROM "+RetSqlTab("SC6,SB1,SC9")
		cQuery2 += " WHERE "+RetSqlFil("SC6,SB1,SC9")
		cQuery2 += " AND "+RetSqlDEL("SC6,SB1,SC9")
		cQuery2 += " AND C6_NUM ='"+QRYC->C5_NUM+"' "
		cQuery2 += " AND C6_PRODUTO = B1_COD "
		cQuery2 += " AND C9_PRODUTO = C6_PRODUTO "
		cQuery2 += " AND C9_PEDIDO = C6_NUM "
		cQuery2 += " AND C9_ITEM = C6_ITEM "
		cQuery2 += " AND C9_BLCRED='  ' "
		cQuery2 += " AND C9_BLEST<>'  ' "
		cQuery2 += " AND C6_LIBWMS<> 0 "
		cQuery2 += " ORDER BY C6_ITEM "

		cQuery2 := ChangeQuery(cQuery2)

		aInside:={}

		TCQuery cQuery2 New Alias "QRYI"
		conout(cQuery2)
		dbGoTop()

		While ! EoF()
			oProdutos:=JsonObject():new()
			For nL:=1 to len(_produtcs)

				IF valtype(_produtcs[nL])=='C'
					cTagName:=_produtcs[nL]
					cContent:=&(_produtcs[nL])
				elseif valtype(_produtcs[nL])=='A'
					cContent:=&(_produtcs[nL,1])
					cTagName:=_produtcs[nL,2]
				else
					loop
				end

				oProdutos[cTagName]		:=cContent
			Next
			aadd(oCabec['products'] , oProdutos)
			DBSKIP()
		END

		aadd(oOrders['orders'],oCabec)

		memowrit('c:\temp\TAKEORDERIT.txt',cQuery2)

		DbSelectArea('QRYI')
		dbCloseArea()

		DbSelectArea('QRYC')
		DBSKIP()
	End

	cOrder:=oOrders:ToJson()

	MEMOWRITE("\logs\UNIA010.txt", cOrder)

	conout('4')

	dbSelectArea("QRYC")
	dbCloseArea()

	If empty(cOrder)

		lOk := .F.
		SetRestFault( 100, "Nenhum registro Encontrado" )
		conout("TAKEORDER + Nao encontrei registros")

	ELse

		::SetResponse(cOrder)

	EndIf

	fwlogmsg("TAKEORDER + Fim consulta de dados protheus ")

Return( lOk )

//----------------------------------------------------------------------
Static Function fAjustQry(cQry)
//----------------------------------------------------------------------
	While AT("&",cQry)<>0
		nPosI:=AT("&",cQry)
		nPosF:=AT("\&",cQry)
		cVari:=Substr(cQry,nPosI+1,nPosF-nPosI-1)
		cQry:=StrTran(cQry,"&"+cVari+"\&",&(cVari))
	End

	cQry := ChangeQuery(cQry)
	MEMOWRITE( "\LOGS\"+CriaTrab(,.F.)+".SQL" ,cQry ) // Grava query na pasta cprova

Return cQry

//----------------------------------------------------------------------------------------------------------------------------------
Static Function LoadHead()
//----------------------------------------------------------------------------------------------------------------------------------
	aRet:={}
	aadd(aRet,{'c5_num','C5_NUM'})
	aadd(aRet,'c5_tipo')
	aadd(aRet,'c5_sitwms')
	aadd(aRet,'c5_cliente')
	aadd(aRet,'c5_lojacli')
	aadd(aRet,'c5_client')
	aadd(aRet,'c5_lojaent')
	aadd(aRet,'c5_transp')
	aadd(aRet,{'a4_cgc','a4_cnpj'})
	aadd(aRet,'a4_nome')
	aadd(aRet,'c5_tipocli')
	aadd(aRet,{'a1_cgc','a1_cgccpf'})
	aadd(aRet,'a1_nome')
	aadd(aRet,'a1_mun')
	aadd(aRet,'a1_est')
	aadd(aRet,'a1_codmun')
	aadd(aRet,'c5_condpag')
	aadd(aRet,'c5_tabela')
	aadd(aRet,'c5_vend1')
	aadd(aRet,'c5_comis1')
	aadd(aRet,'c5_vend2')
	aadd(aRet,'c5_comis2')
	aadd(aRet,'c5_vend3')
	aadd(aRet,'c5_comis3')
	aadd(aRet,'c5_vend4')
	aadd(aRet,'c5_comis4')
	aadd(aRet,'c5_vend5')
	aadd(aRet,'c5_comis5')
	aadd(aRet,'c5_desc1')
	aadd(aRet,'c5_desc2')
	aadd(aRet,'c5_desc3')
	aadd(aRet,'c5_desc4')
	aadd(aRet,'c5_descfi')
	aadd(aRet,'c5_emissao')
	aadd(aRet,'c5_parc1')
	aadd(aRet,'c5_data1')
	aadd(aRet,'c5_parc2')
	aadd(aRet,'c5_data2')
	aadd(aRet,'c5_parc3')
	aadd(aRet,'c5_data3')
	aadd(aRet,'c5_parc4')
	aadd(aRet,'c5_data4')
	aadd(aRet,'c5_tpfrete')
	aadd(aRet,'c5_frete')
	aadd(aRet,'c5_seguro')
	aadd(aRet,'c5_despesa')
	aadd(aRet,'c5_fretaut')
	aadd(aRet,'c5_moeda')
	aadd(aRet,'c5_pesol')
	aadd(aRet,'c5_pbruto')
	aadd(aRet,'c5_volume1')
	aadd(aRet,'c5_volume2')
	aadd(aRet,'c5_volume3')
	aadd(aRet,'c5_volume4')
	aadd(aRet,'c5_especi1')
	aadd(aRet,'c5_especi2')
	aadd(aRet,'c5_especi3')
	aadd(aRet,'c5_especi4')
	aadd(aRet,'c5_mennota')
	aadd(aRet,'c5_txmoeda')
	aadd(aRet,'c5_fecent')
//aadd(aRet,{'"1.01"',"VERSION"})

return aRet

//----------------------------------------------------------------------------------------------------------------------------------
Static Function LoadItems()
//----------------------------------------------------------------------------------------------------------------------------------
	aRet:={}
	aadd(aRet,'c6_item')
	aadd(aRet,'c6_produto')
	aadd(aRet,'c6_um')
	aadd(aRet,{'c6_libwms','c6_qtdven'})
	aadd(aRet,'c6_prcven')
	aadd(aRet,{'c6_libwms*c6_prcven','c6_valor'})
	aadd(aRet,{'c9_qtdlib2','c6_qtdlib'})
	aadd(aRet,'c6_qtdlib2')
	aadd(aRet,'c6_segum')
	aadd(aRet,'c6_oper')
	aadd(aRet,'c6_tes')
	aadd(aRet,'c6_unsven')
	aadd(aRet,'c6_local')
	aadd(aRet,'c6_cf')
	aadd(aRet,'c6_qtdent')
	aadd(aRet,'c6_qtdent2')
	aadd(aRet,'c6_cli')
	aadd(aRet,'c6_descont')
	aadd(aRet,'c6_valdesc')
	aadd(aRet,'c6_entreg')
	aadd(aRet,'c6_loja')
	aadd(aRet,'c6_num')
	aadd(aRet,'c6_comis1')
	aadd(aRet,'c6_comis2')
	aadd(aRet,'c6_comis3')
	aadd(aRet,'c6_comis4')
	aadd(aRet,'c6_comis5')
	aadd(aRet,'c6_pedcli')
	aadd(aRet,'c6_descri')
	aadd(aRet,'c6_prunit')
	aadd(aRet,'c6_nfori')
	aadd(aRet,'c6_seriori')
	aadd(aRet,'c6_itemori')
	aadd(aRet,'c6_localiz')

return aRet
