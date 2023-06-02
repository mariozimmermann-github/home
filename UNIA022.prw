#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
/*
+-----------+-----------+-------+------------------------------------------------------------------+------+----------+
| Funcao    | UNIA022   | Autor | Manoel M Mariante                                                | Data |dez/2021  |
|-----------+-----------+-------+------------------------------------------------------------------+------+----------|
| Descricao | PE na rotina de Recalc de Comissoes (FINA440) que altera base                                          |
|           |  da comissão                                                                                           |
|           |                                                                                                        |
|-----------+--------------------------------------------------------------------------------------------------------|
| Sintaxe   | executado via PE F440ABAS                                                                              |
+-----------+--------------------------------------------------------------------------------------------------------+
| Alterações| 29/12-criterio da ação de incentivo foi alterada,e levada para o processo de comissão decrescente      |
|           |                                                                                                        |
+-----------+--------------------------------------------------------------------------------------------------------+
*/
User Function UNIA022(abases)

/*
	Local cQuery	:=cLog:=''
	Local nBaseAtual
	Local nTotIncen	:=nValFat:=0
	Local aArea		:=GetArea()
	Local cAliasT
	Local nPercPar
	Local _CRLF		:=chr(13)+chr(10)

	IF !SuperGetMV('ES_CALCODE',.f.,.f.)
		If SuperGetMV('ES_LGCOMIN',.f.,.f.).and.!Empty(cLog)
			MEMOWRIT('c:\temp\INCENT_TITULO_'+ALLTRIM(SE1->E1_NUM)+'_'+ALLTRIM(SE1->E1_PARCELA)+'_'+DTOS(msDate())+'_'+StrTran(Time(),':','')+'.csv','parametro desabilitado')
		end
		Return abases
	End

	If !VALTYPE(aBases)=='A' .or. Len(aBases)=0
		If SuperGetMV('ES_LGCOMIN',.f.,.f.).and.!Empty(cLog)
			MEMOWRIT('c:\temp\INCENT_TITULO_'+ALLTRIM(SE1->E1_NUM)+'_'+ALLTRIM(SE1->E1_PARCELA)+'_'+DTOS(msDate())+'_'+StrTran(Time(),':','')+'.csv','aBASES não é array')
		end
		Return abases
	End

	nBaseAtual:=abases[1,4]

	cQuery := " SELECT F2_FILIAL,F2_DOC,F2_SERIE , F2_VALFAT" //,D2_PRUNIT, D2_QUANT, D2_PRCVEN , D2_COD "+_CRLF
	cQuery += " FROM " + RetSQLTab("SF2,SD2")+_CRLF
	cQuery += " WHERE "+RetSqlFil("SF2,SD2")+_CRLF
	cQuery += " AND D2_DOC=F2_DOC "+_CRLF
	cQuery += " AND D2_SERIE=F2_SERIE "+_CRLF
	cQuery += " AND F2_DUPL='"+SE1->E1_NUM+"' "+_CRLF
	cQuery += " AND F2_PREFIXO='"+SE1->E1_PREFIXO+"' "+_CRLF
	//cQuery += " AND D2_PRUNIT> D2_PRCVEN  "+_CRLF

	cQuery += " AND (SELECT COUNT(*) "
	cQuery += "  FROM " + RetSqlTab("SB1") +_CRLF
	cQuery += "  WHERE " + RetSqlDel("SB1") +_CRLF
	cQuery += "  AND " + RetSqlFil("SB1") +_CRLF
	cQuery += "  AND D2_COD=B1_COD "+_CRLF
	cQuery += "  AND B1_PRCINCE<>0 "+_CRLF
	cQuery += "  AND B1_INIICEN<=D2_EMISSAO "+_CRLF
	cQuery += "  AND B1_FIMICEN>= D2_EMISSAO ) > 0"+_CRLF

	cQuery := ChangeQuery( cQuery )

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),(cAliasT:=GetNextAlias()),.F.,.T. )

	IF Eof()
		Return abases
	End
	nValFat	:=(cAliasT)->F2_VALFAT

	DbSelectArea('SD2')
	DbSetOrder(3)
	dbSeek((cAliasT)->F2_FILIAL+(cAliasT)->F2_DOC+(cAliasT)->F2_SERIE)

	WHILE (cAliasT)->F2_FILIAL+(cAliasT)->F2_DOC+(cAliasT)->F2_SERIE == D2_FILIAL+D2_DOC+D2_SERIE //.AND. !EOF()

		iF Empty(cLog)
			cLog+='NUMERO NF ;'+SD2->D2_DOC+chr(13)+chr(10)
			cLog+='DATA E HORA DO CALCULO ;'+DTOC(msDate())+' '+time()+chr(13)+chr(10)
		end

		DbSelectArea('SB1')
		DbSetOrder(1)
		dbSeek(xFilial('SB1')+SD2->D2_COD)

		DbSelectArea('SD2')

		nPerDesc	:=(1-(SD2->D2_PRCVEN / SD2->D2_PRUNIT))*100
		if SB1->B1_PRCINCE ==0
			nPrcIncent	:=SD2->D2_PRCVEN //- (SD2->D2_PRUNIT * SB1->B1_PRCINCE / 100)

		else
			IF nPerDesc <= SB1->B1_PRCINCE
				nPrcIncent	:=SD2->D2_PRUNIT
				//cfe reuniao em 27/12 se desconto ultrapassar o limite não terá incentivo
			else
				nPrcIncent	:=SD2->D2_PRCVEN //- (SD2->D2_PRUNIT * SB1->B1_PRCINCE / 100)
			end
		END

		nTotIncen	+=SD2->D2_QUANT * nPrcIncent


		cLog+='Produto ;'+SD2->D2_COD+chr(13)+chr(10)
		cLog+='Descrição ;'+ALLTRIM(SB1->B1_DESC)+chr(13)+chr(10)
		cLog+='Preço de Tabela;'+CValToChar(SD2->D2_PRUNIT)+chr(13)+chr(10)
		cLog+='Preço de Venda;'+CValToChar(SD2->D2_PRCVEN)+chr(13)+chr(10)
		cLog+='Desconto no Pedido;'+CValToChar(nPerDesc)+chr(13)+chr(10)

		cLog+='Quantidade;'+CValToChar(SD2->D2_QUANT)+chr(13)+chr(10)
		cLog+='Base Comissão Normal;'+CValToChar(SD2->D2_QUANT * nPrcIncent)+chr(13)+chr(10)

		cLog+='Percent de Incentivo ;'+CValToChar(SB1->B1_PRCINCE)+chr(13)+chr(10)
		cLog+='Preço Maximo para Incentivo ;'+CValToChar(nPrcIncent)+chr(13)+chr(10)
		cLog+='Nova Base Comissão ;'+CValToChar(SD2->D2_QUANT * nPrcIncent)+chr(13)+chr(10)

		dbSkip()
	end

	DbSelectArea(cAliasT)
	dbCloseArea()

	RestArea(aArea)

	If !Empty(cLog)
		nPercPar	:=SE1->E1_VALOR / nValFat

		nNewBase:=nTotIncen * nPercPar
		//nNewBase:=nBaseAtual + (nTotIncen * nPercPar)

		abases[1,4]:=nNewBase

		cLog+='TOTAIS ; '+chr(13)+chr(10)
		cLog+='Base Comissão Parcela ;'+CValToChar(nBaseAtual)+chr(13)+chr(10)
		cLog+='Total do Incentivo ;'+CValToChar(nTotIncen)+chr(13)+chr(10)
		cLog+='Total da NF;'+CValToChar(nValFat)+chr(13)+chr(10)
		cLog+='Perc Parcela Sobre a NF ;'+CValToChar(nPercPar*100)+chr(13)+chr(10)
		cLog+='Valor da Parcela ;'+CValToChar(SE1->E1_VALOR )+chr(13)+chr(10)
		cLog+='Nova Base ;'+CValToChar(nNewBase)+chr(13)+chr(10)
	end

	If SuperGetMV('ES_LGCOMIN',.f.,.f.).and.!Empty(cLog)
		memowrit('c:\temp\uni.txt',cQuery)

		MEMOWRIT('c:\temp\INCENT_TITULO_'+ALLTRIM(SE1->E1_NUM)+'_'+ALLTRIM(SE1->E1_PARCELA)+'_'+DTOS(msDate())+'_'+StrTran(Time(),':','')+'.csv',cLog)
	end
*/

Return abases
