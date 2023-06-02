#Include "Protheus.Ch"
#Include "TopConn.Ch"
#include "rwmake.ch"
#include "totvs.ch"
/*
+-----------+-----------+-------+-------------------------------------+------+----------+
| Funcao    | UNIA024   | Autor | Manoel M Mariante                   | Data |DEZ/2021  |
|-----------+-----------+-------+-------------------------------------+------+----------|
| Descricao | Esta rotina tem o objetivo Geração descontos de comissões	                |
|           |                                                                           |
|           |                                                                           |
|-----------+---------------------------------------------------------------------------|
| Sintaxe   | executado via menu                                                        |
+-----------+---------------------------------------------------------------------------+
*/

User Function UNIA024()

	Local cPerg             :='UNIA024'
	Private aSays           := { }
	Private aButtons        := { }
	Private cCadastro       := OemToAnsi('Calculo da Comissão Decrescente')
	Private nOpca           := 0
	Private lOk             :=.t.
	Private _CRLF           :=CHR(13)+chr(10)
	Private lSendMail		:=.f.
	Private aRelLog			:={}

	UNIPUTSX1( cPerg,'01','Emissão de?'			        ,'MV_PAR01','D',08,0,'G','',/*DEF01*/ '', /*DEF02*/ '',/*DEF03*/ '',/*DEF04*/ '',/*DEF05*/ '', 'mv_ch2',''   )
	UNIPUTSX1( cPerg,'02','Emissão Até?'		        ,'MV_PAR02','D',08,0,'G','',/*DEF01*/ '', /*DEF02*/ '',/*DEF03*/ '',/*DEF04*/ '',/*DEF05*/ '', 'mv_ch2',''   )
	UNIPUTSX1( cPerg,'03','Do Vendedor ?'       		,'MV_PAR03','C',06,0,'G','',''          , ''          ,''          ,/*DEF04*/ '',/*DEF05*/ '', 'mv_ch4','SA3')
	UNIPUTSX1( cPerg,'04','Até o Vendedor ?'    		,'MV_PAR04','C',06,0,'G','',''         	, ''          ,''          ,/*DEF04*/ '',/*DEF05*/ '', 'mv_ch5','SA3')
	//UNIPUTSX1( cPerg,'13','Pasta/Nome Arquivo Excel?'	,'MV_PAR13','C',99,0,'G','',''			, ''     	  ,''          			,/*DEF04*/ '',/*DEF05*/ '', 'mv_ch6','DIR')

	Pergunte(cPerg,.f.)

	AADD(aSays,OemToAnsi('Esta rotina tem o objetivo gerar os valores de comissão decrescente' ) )
	AADD(aSays,OemToAnsi('' ) )

	AADD(aButtons, { 5,.T.,{|o| lOk:=Pergunte(cPerg,.t.)     }} )	//parametros
	AADD(aButtons, { 1,.T.,{|o| nOpca:=1,FechaBatch()        }} )	//ok
	AADD(aButtons, { 2,.T.,{|o| nOpca:=0,FechaBatch()        }} )  	//cancelar

	FormBatch( cCadastro, aSays, aButtons )

	If !lOk.or.nOpca==0
		MsgInfo('Processamento Cancelado')
		return
	end

	If nOpca==1 //ok
		RptStatus({|| fGeraComis(cPerg)}, "Aguarde...", "Processando...")
	end

Return

//-----------------------------------------------------------------------------------------
Static Function fGeraComis(cPerg)
//-----------------------------------------------------------------------------------------
	Local cSelect   :='', cQuery:=''
	Local nTotLines :=0
	Local nQuantos	:=0

	IF !msgbox("Deseja iniciar o calculo da comissão ?","Atenção","YESNO")
		return .f.
	End

	//excluindo registros do periodo

	cQuery:=" UPDATE "+RetSqlName("SE3")
	cQuery+=" SET D_E_L_E_T_='*' , R_E_C_D_E_L_=R_E_C_N_O_,E3_OBSERV='Excl em "+dtoc(ddatabase)+"' "+_CRLF
	cQuery+=" WHERE E3_EMISSAO  BETWEEN '"+DTOS(MV_PAR01)+"' AND '"+DTOS(MV_PAR02)+"'"+_CRLF
	cQuery+=" AND E3_VEND BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"' "+_CRLF
	cQuery+=" AND E3_ORIGLAN='1'"+_CRLF
	cQuery+=" AND E3_FILIAL='"+xFilial('SE3')+"' "

	MemoWrite("\LOGS\unia024DEL.SQL",cQuery)

	nRet:=TcSqlExec(cQuery)
	If nRet<0
		MsgInfo("Atenção, erro na exclusão das comissões ","Erro na Exclusão")
		Return
	End

	//incluindo os registros

	cSelect := " SELECT SE3.* "+_CRLF
	cSelect += " FROM " + RetSqlTab("SE3") +_CRLF
	cSelect += " WHERE " + RetSqlDel("SE3") +_CRLF
	cSelect += "  AND " + RetSqlFil("SE3") +_CRLF
	cSelect += "  AND E3_EMISSAO  BETWEEN '"+DTOS(MV_PAR01)+"' AND '"+DTOS(MV_PAR02)+"'"+_CRLF
	cSelect += "  AND E3_VEND BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"' "+_CRLF
	cSelect += "  AND E3_COMIS<>0 "+_CRLF
	cSelect += "  AND E3_TIPO ='NF' "+_CRLF
	cSelect += "  AND (SELECT COUNT(*) "
	cSelect += "    FROM " + RetSqlTab("SF2,SD2,SC5") +_CRLF
	cSelect += "    WHERE " + RetSqlDel("SF2,SD2,SC5") +_CRLF
	cSelect += "    AND " + RetSqlFil("SF2,SD2,SC5") +_CRLF
	cSelect += "    AND F2_DUPL=E3_NUM "+_CRLF
	cSelect += "    AND F2_PREFIXO=E3_PREFIXO "+_CRLF
	cSelect += "    AND D2_DOC=F2_DOC "+_CRLF
	cSelect += "    AND D2_SERIE=F2_SERIE"+_CRLF
	cSelect += "    AND D2_CLIENTE=F2_CLIENTE"+_CRLF
	cSelect += "    AND D2_PRUNIT > D2_PRCVEN"+_CRLF
	cSelect += "    AND D2_LOJA=F2_LOJA"+_CRLF
	cSelect += "    AND D2_PEDIDO=C5_NUM ) > 0"+_CRLF
	cSelect += " ORDER BY E3_VEND  "

	memowrit('C:\TEMP\UNIA024INC.sql',cSelect)

	dbUseArea( .T.,"TOPCONN", TCGENQRY(,,cSelect),"TRB", .F., .T.)
	Count To nTotLines

	SetRegua(nTotLines)

	DbSelectArea( "TRB" )
	DbGoTop()

	If Eof()
		Msginfo('Não foram encontradas comissões dentro dos parâmetros informados.')
		return
	End

	While !eof()
		//alert('processando '+TRB->E3_NUM+' '+TRB->E3_PREFIXO+' '+E3_TIPO)

		IncRegua()
		nQuantos++

		nDecresc	:=0
		nTotDecr	:=0
		nD2Total	:=0
		nPercDec	:=0
		cLog		:=''
		cPrdLog		:=''

		cLog+='TITULO						   ;VALOR COMISSAO				 ;BASE COMISSAO				  ;SEQ						  ;EMISSAO'+_CRLF
		cLog+=TRB->E3_NUM+'/'+TRB->E3_PREFIXO+';'+CValToChar(TRB->E3_COMIS)+';'+CValToChar(TRB->E3_BASE)+';'+CValToChar(TRB->E3_SEQ)+';'+CValToChar(STOD(TRB->E3_EMISSAO))+_CRLF

		DbSelectArea('SF2')
		DbSetOrder(1)
		If !dbSeek(xFilial('SF2')+TRB->E3_NUM+TRB->E3_SERIE) //alterar se o prefixo for diferente da serie
			//alert('pulei 1 '+TRB->E3_NUM+TRB->E3_SERIE)
			DbSelectArea( "TRB" )
			dbSkip()
			
			loop
		end
		cLog+=_CRLF
		cLog+='NOTA FISCAL                   ;VALOR                         ;EMISSAO'+_CRLF
		cLog+=SF2->F2_DOC+'/'+SF2->F2_SERIE+';'+CValToChar(sf2->f2_valfat)+';'+CValToChar(SF2->F2_EMISSAO)+_CRLF
		lFirst:=.t.

		DbSelectArea('SD2')
		DbSetOrder(3)
		dbSeek(xFilial('SD2')+SF2->F2_DOC+SF2->F2_SERIE)
		while xFilial('SD2')+SF2->F2_DOC+SF2->F2_SERIE == D2_FILIAL+D2_DOC+D2_SERIE
			IF SD2->D2_PRCVEN == SD2->D2_PRUNIT
				DbSelectArea('SD2')
				dbSkip()
				//alert('pulei 2')
				LOOP
			eND
			DbSelectArea('SC5')
			DbSetOrder(1)
			dbSeek(xFilial('SC5')+SD2->D2_PEDIDO)

			If lFirst
				cLog+=_CRLF
				cLog+='PEDIDO;'+SD2->D2_PEDIDO+_CRLF

				cLog+=_CRLF
				cLog+='PRODUTO;TABELA;% DE DESCONTO; TOTAL DO ITEM;% DESCRESCIMO;OBSERVAÇÃO'+_CRLF

				lFirst:=.f.
			end

			nPerDesc	:=(1-(SD2->D2_PRCVEN / SD2->D2_PRUNIT))*100

			nPrcIncent	:=Posicione('SB1',1,xFilial('SB1')+SD2->D2_COD,'B1_PRCINCE') //PREÇO DE INCENTIVO

			If nPerDesc <=nPrcIncent //o desconto concendido ao cliente está dentro do % de incentivo, não terá redução da comissão				cLog+=SD2->D2_COD+';'+SC5->C5_TABELA+';'+CValToChar(nPerDesc)+';'+CValToChar(SD2->D2_TOTAL)+';'+CValToChar(0*100)+';NÃO POSSUI REGRA PARA CALCULO DE DESCONTO DECRESCENTE+_CRLF
				//alert('pulei 3')
				cLog+=SD2->D2_COD+';'+SC5->C5_TABELA+';'+CValToChar(nPerDesc)+';'+CValToChar(SD2->D2_TOTAL)+';'+CValToChar(0*100)+';PRODUTO SOB INCENTIVO DE '+CValToChar(nPrcIncent)+'%'+_CRLF

				DbSelectArea('SD2')
				dbSkip()
				loop
			End

			cQuery := " SELECT TOP 1 * "+_CRLF
			cQuery += " FROM " + RetSqlTab("SZ1") +_CRLF
			cQuery += " WHERE " + RetSqlDel("SZ1") +_CRLF
			cQuery += " AND " + RetSqlFil("SZ1") +_CRLF
			cQuery += " AND Z1_TABELA='"+SC5->C5_TABELA+"' "+_CRLF
			cQuery += " AND Z1_VIGDE<='"+TRB->E3_EMISSAO+"' AND Z1_VIGATE>='"+TRB->E3_EMISSAO+"' "+_CRLF
			cQuery += " AND Z1_DESDE<="+STR(nPerDesc,11,2)+" AND Z1_DESATE>="+STR(nPerDesc,11,2)+" "+_CRLF
			cQuery += " ORDER BY Z1_DESDE "+_CRLF

			dbUseArea( .T.,"TOPCONN", TCGENQRY(,,cQuery),"TRX", .F., .T.)

			IF !EOF()
				//alert('pulei 5')

				nDecresc:=TRX->Z1_DECRESC/100
				nTotDecr+=(SD2->D2_TOTAL * nDecresc)
				nD2Total+=SD2->D2_TOTAL

				cLog+=SD2->D2_COD+';'+SC5->C5_TABELA+';'+CValToChar(nPerDesc)+';'+CValToChar(SD2->D2_TOTAL)+';'+CValToChar(TRX->Z1_DECRESC)+';'+_CRLF
				cPrdLog+=alltrim(SD2->D2_COD)+'='+ALLTRIM(str(nPerDesc,6,2))+'%->'+ALLTRIM(str(TRX->Z1_DECRESC,6,2))+'%,'
			else
				//alert('pulei 6')
				cLog+=SD2->D2_COD+';'+SC5->C5_TABELA+';'+CValToChar(nPerDesc)+';'+CValToChar(SD2->D2_TOTAL)+';'+CValToChar(0*100)+';NÃO POSSUI REGRA PARA CALCULO DE DESCONTO DECRESCENTE+_CRLF

			END

			DbSelectArea('TRX')
			DBCLOSEAREA()

			DbSelectArea('SD2')
			dbSkip()
		end
		nPercDec	:=nTotDecr/nD2Total
		cLog+=_CRLF

		cLog+='TOTAL DE DESCONTO DE COMISSAO;TOTAL DOS ITENS ; % DE DECRESCIMO TOTAL '+_CRLF
		cLog+=CValToChar(nTotDecr)+';'+CValToChar(nD2Total)+';'+CValToChar(nPercDec*100)+_CRLF

		fSavNewSE3(nPercDec,nD2Total,nTotDecr)

		If SuperGetMV('ES_LGCOMDE',.f.,.f.)
			//alert('vou grava')
			MEMOWRIT('c:\temp\TITULO'+ALLTRIM(TRB->E3_NUM)+'_'+ALLTRIM(TRB->E3_PARCELA)+'_'+ALLTRIM(TRB->E3_SEQ)+'_'+DTOS(msDate())+'_'+StrTran(Time(),':','')+'.CSV',cLog)
		end

		DbSelectArea( "TRB" )
		dbSkip()

	end
	DbSelectArea( "TRB" )

	dbcloseArea()

	MsgInfo('Calculo Finalizado', 'Finalizado')
return

//-------------------------------------------------------------------------------------
Static Function fSavNewSe3(_XPORC,_XTOT,_XDESC)
//--------------------------------------------------------------------------------------
	Local aArea:=GetArea()
	If nPercDec=0
		return
	end

	DbSelectArea('SE3')
	RecLock('SE3',.t.)
	SE3->E3_FILIAL	:=TRB->E3_FILIAL
	SE3->E3_EMISSAO	:=STOD(TRB->E3_EMISSAO)
	SE3->E3_SERIE	:=TRB->E3_SERIE
	SE3->E3_CODCLI	:=TRB->E3_CODCLI
	SE3->E3_LOJA	:=TRB->E3_LOJA
	SE3->E3_VEND	:=TRB->E3_VEND
	SE3->E3_NUM		:=TRB->E3_NUM
	SE3->E3_PREFIXO	:=TRB->E3_PREFIXO
	SE3->E3_PARCELA	:=TRB->E3_PARCELA
	SE3->E3_TIPO	:=TRB->E3_TIPO
	//SE3->E3_DATA	:=TRB->E3_DATA
	SE3->E3_PEDIDO	:=TRB->E3_PEDIDO
	SE3->E3_AJUSTE	:=TRB->E3_AJUSTE
	SE3->E3_VENCTO	:=stod(TRB->E3_VENCTO)
	SE3->E3_MOEDA	:=TRB->E3_MOEDA

	SE3->E3_SDOC	:=''
	SE3->E3_BASE	:=_XTOT*(-1)
	SE3->E3_PORC	:=_XPORC*100
	SE3->E3_COMIS	:=_XDESC*(-1)
	SE3->E3_BAIEMI	:=' '
	SE3->E3_SEQ		:=''
	SE3->E3_ORIGEM	:=''
	SE3->E3_ORIGLAN	:='1' //DESCRESCIMO
	SE3->E3_OBSERV	:=cPrdLog
	MsUnlock()

	cLog+='BASE;% DE DECRESCIMO ; COMISSAO'+ _CRLF
	cLog+=CValToChar(SE3->E3_BASE)+';'+CValToChar(SE3->E3_PORC)+';'+CValToChar(SE3->E3_COMIS) + _CRLF

	REstArea(aArea)

Return
//-------------------------------------------------------------------------------
Static Function UNIPUTSX1( cX1_GRUPO, cX1_ORDEM,cX1_PERGUNT, cX1_VAR01,  cX1_TIPO, cX1_TAMANHO,cX1_DECIMAL,cX1_GSC,cX1_VALID,cX1_DEF01, cX1_DEF02,cX1_DEF03,cX1_DEF04, cX1_DEF05, cX1_VARIAVL,cX1_F3)
	//-------------------------------------------------------------------------------
	cX1_GRUPO:=PADR(Alltrim(cX1_GRUPO),10,' ')
	dbSelectArea("SX1")
	dbSetOrder(1)
	If !dbSeek(cX1_GRUPO+cX1_ORDEM)
		Reclock("SX1",.t.)
	Else
		Reclock("SX1",.F.)
	end
	X1_GRUPO	:=cX1_GRUPO
	X1_ORDEM	:=cX1_ORDEM
	X1_PERGUNT	:=cX1_PERGUNT
	X1_VARIAVL	:=cX1_VARIAVL
	X1_TIPO		:=cX1_TIPO
	X1_TAMANHO	:=cX1_TAMANHO
	X1_DECIMAL	:=cX1_DECIMAL
	X1_GSC		:=cX1_GSC
	X1_VALID	:=cX1_VALID
	X1_DEF01	:=cX1_DEF01
	X1_DEF02	:=cX1_DEF02
	X1_DEF03	:=cX1_DEF03
	X1_DEF04	:=cX1_DEF04
	X1_DEF05	:=cX1_DEF05
	X1_VAR01	:=cX1_VAR01
	X1_F3   	:=cX1_F3
	msUnlock()

Return



//teste de commit
//----------------------------------------------------------------------------
Static Function fGeraExcel(aRelato,aLog,dVcto)
//----------------------------------------------------------------

	Local oFWMsExcel
	Local cArquivo      := ALLTRIM(MV_PAR13)
	Local cAba          :="Titulos"
	lOCAL nH,nL
	Local _cNome		:='Titulos Gerados'

	If ! RIGHt(upper(cArquivo),5) <> '.XLSX'
		cArquivo+='.xlsx'
	End

	//Criando o objeto que irá gerar o conteúdo do Excel
	oFWMsExcel := FwMsExcelXlsx():New()

	//crianda a aba 1 - lista das comissoes
	oFWMsExcel:AddworkSheet(cAba) //Não utilizar número junto com sinal de menos. Ex.: 1-

	//Criando a Tabela dentro da aba
	oFWMsExcel:AddTable(cAba,_cNome)

	//Criando Colunas da tabelas
	For nH:=1 to Len(aCabec)

		oFWMsExcel:AddColumn(cAba,_cNome,aCabec[nH,1],2,aCabec[nH,3]) //Codigo de formatação ( 1-General,2-Number,3-Monetário,4-DateTime )

	Next
	lLin:=.t.
	//Criando as Linhas
	For nL:=1 to Len(aRelato)
		aLinha:={}
		For nH:=1 to Len(aCabec)
			Aadd(aLinha, aRelato[nL, aCabec[nH,2] ] )
		Next
		oFWMsExcel:AddRow(cAba,_cNome,aLinha)
		if lLin
			oFWMsExcel:SetBold(.T.)
			lLin:=.f.
		else
			oFWMsExcel:SetBold(.f.)
			lLin:=.t.

		end
		//nVlBruto+=aRelato[nL,_POSCOM]
	Next

	oFWMsExcel:SetBold(.f.)

	//crianda a aba 2 = LOG DE PROCESSAMENTO
	cAba	:="Log"
	_cNome	:="Log de Processamento Em "+dtoc(dDataBase)
	oFWMsExcel:AddworkSheet(cAba) //Não utilizar número junto com sinal de menos. Ex.: 1-

	//Criando a Tabela dentro da aba
	oFWMsExcel:AddTable(cAba,_cNome)

	//Criando Colunas da tabelas

	oFWMsExcel:AddColumn(cAba,_cNome,"Log",1,1) //Codigo de formatação ( 1-General,2-Number,3-Monetário,4-DateTime )

	For nL:=1 to Len(aLog)
		oFWMsExcel:AddRow(cAba,_cNome,{aLog[nL]	})
	Next
	//Ativando o arquivo e gerando o xml
	oFWMsExcel:Activate()
	oFWMsExcel:GetXMLFile(cArquivo)

	If file(cArquivo)
		MsgInfo('Planilha salva: '+cArquivo)
		//Abrindo o excel e abrindo o arquivo xml
		oExcel := MsExcel():New()             //Abre uma nova conexão com Excel
		oExcel:WorkBooks:Open(cArquivo)     //Abre uma planilha
		oExcel:SetVisible(.T.)                 //Visualiza a planilha

	else
		MsgInfo('Problema em salvar a planilha: '+cArquivo)
	End
	oExcel:Destroy()


Return
