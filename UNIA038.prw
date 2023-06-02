
#include 'topconn.ch'
#include "totvs.ch"
#include "TBICONN.CH"
#include "TOTVSWebSrv.ch" 

/*/{Protheus.doc} User Function UNIA038
    Rotina para executar a integra��o via API VNDA
    @type  Function
    @author 1.0
    @since 10/12/2021
    @version 1.0
    @see (links_or_references) 
    /*/
User Function UNIA038()
    Private oJsonPedi     := JsonObject():new()
    Private oJsonPedAll  := JsonObject():new()
    Private oJsonClie     := JsonObject():new()

    If !IsBlind()
        INTEGRAMENU()   
    Else
        INTREGAJOB()
    EndIf    
Return 

/*/{Protheus.doc} INTEGRAMENU
    Integra��o API Pedidos VNDA via menu
    @type  Static Function
    @author Willian Kaneta
    @since 16/12/2021
    @version 1.0
/*/
Static Function INTEGRAMENU()
    Private cPerg   	   := "UNIA038"

    CriaSX1()

    If !Pergunte(cPerg,.T.)
		Return Nil
	EndIf
	
    FWMsgRun(, {|| GERAPEDIDOS() }, 'Processando', 'Importando Pedidos de Vendas E-commerce VNDA...' )

    MsgInfo("Importa��o finalizada...Verificar!")
Return Nil

/*/{Protheus.doc} INTREGAJOB
    Integra��o API Pedidos VNDA via Schedule
    @type  Static Function
    @author Willian Kaneta
    @since 16/12/2021
    @version 1.0
/*/
Static Function INTREGAJOB()

    PREPARE ENVIRONMENT EMPRESA "01" FILIAL "0101"
        MV_PAR01 := ddatabase
        MV_PAR02 := ddatabase
        MV_PAR03 := "V01"
        MV_PAR04 := "001"
        MV_PAR05 := "RS9988"
        MV_PAR06 := "DEP"

        GERAPEDIDOS()

    RESET ENVIRONMENT

Return Nil

/*/{Protheus.doc} User Function GERAPEDIDOS
    Gera os pedidos de vendas via API VNDA
    @type  Function
    @author Willian Kaneta
    @since 13/12/2021
    @version 1.0
    /*/
Static Function GERAPEDIDOS()
    Local cUrlAPI       := Alltrim(supergetmv('MV_XURLVNDA',.f.,'https://selecionadosuniagro.vnda.com.br/api/v2' ))
    Local cApiKey       := Alltrim(supergetmv('MV_XAPIKEY',.f.,'Bearer 7LnuAcermCWVuf1nuVEgprP2' ))
    Local cStartDate    := SUBSTR(DTOC(MV_PAR01),7,4)+"-"+SUBSTR(DTOC(MV_PAR01),4,2)+"-"+SUBSTR(DTOC(MV_PAR01),1,2)
    Local cFinisDate    := SUBSTR(DTOC(MV_PAR02),7,4)+"-"+SUBSTR(DTOC(MV_PAR02),4,2)+"-"+SUBSTR(DTOC(MV_PAR02),1,2)
    Local _cOper        := SUPERGETMV('MV_XOPESAI',.f.,'01' )
    //Local _cNatSC5      := SUPERGETMV('MV_XNATSC5',.f.,'998877    ' )
    Local nTimeOut      := 120
    Local nX,nY,nZ      := 0
    Local nPage         := 1
	Local nTotPages     := 1
    Local aHeader       := {}
    Local aPedItens     := {}
    Local aItemPV       := {}
    Local cHeadRet1     := ""
    Local cHeadRet2     := ""
    Local cErro         := ""
    Local cCodPedido    := ""
    Local cCgc          := ""
    Local _cTransp      := ""

    Private lMsErroAuto := .F.
    Private _cCodTab    := PadR(MV_PAR03,tamsx3('DA0_CODTAB')[1])
    Private _cCodPag    := MV_PAR04
    Private _cVend1     := MV_PAR05
    Private _cArmEst    := MV_PAR06

    aadd(aHeader,'Authorization: '+cApiKey)

    While nPage <= nTotPages 

        cRet:= HttpGet(cUrlAPI+'/orders','start='+cStartDate+'&finish='+cFinisDate+'&page='+Alltrim(cValToChar(nPage)),nTimeOut,aHeader,@cHeadRet1)

        If Empty(cRet)
            If !IsBlind()
                Alert("Nenhum dado retornado pela integra��o")
            EndIf
            return
        Endif
        
        cErro := oJsonPedAll:fromJSON( cRet )

        If !Empty(cErro)
            Alert(cErro)
            return
        Endif
        
        If nPage == 1 
            nPosIni   := At("total_pages",cHeadRet1)
            If nPosIni <> 0
                nPosIni += 13
                cTotPag := SUBSTR(cHeadRet1,nPosIni,(Len(cHeadRet1)-(nPosIni-1)))
                nPosIni := At(":",cTotPag)
                nPosFim := At(",",cTotPag)
                nTotPages := VAL(SubStr(cTotPag, nPosIni, nPosFim))
            EndIf
        EndIf
        
        For nX := 1 To Len(oJsonPedAll)
            If oJsonPedAll[nX]['status'] == "confirmed"
                lSB1OK      := .F.
                aPedItens   := {}
                aItemPV     := {}
                oJsonPedi   := oJsonPedAll[nX]
                cCodPedido  := oJsonPedi['code']
                //Grava dados do pedido
                DbSelectArea("SZ7")
                SZ7->(DbSetOrder(1))

                If !SZ7->(MsSeek(xFilial("SZ7")+cCodPedido))
                    cIdCliente  := oJsonPedi['client_id']
                    _nVlrDescont := oJsonPedi['discount_price']
                    _nVlrFrete := oJsonPedi['shipping_price']
                    //Consulta se os dados do cliente
                    cRet := HttpGet(cUrlAPI+'/clients/'+cValToChar(cIdCliente),,nTimeOut,aHeader,@cHeadRet2)

                    If Empty(cRet)
                        If !IsBlind()
                            Alert("Nenhum dado na consulta de clientes retornado pela integra��o")
                        EndIf
                        return
                    Endif

                    cErro := oJsonClie:fromJSON( cRet )

                    If !Empty(cErro) 
                        Alert(cErro)
                        return
                    Endif
                    
                    If oJsonClie['cnpj'] != Nil
                        cCgc := Padr(oJsonClie['cnpj'],TamSx3("A1_CGC")[1])
                    ElseIf oJsonClie['cpf'] != Nil
                        cCgc := Padr(oJsonClie['cpf'],TamSx3("A1_CGC")[1])
                    EndIf

                    If oJsonPedi['delivery_type'] != Nil
                        If oJsonPedi['delivery_type'] == "normal"
                            _cTransp := "000029"
                        ElseIf oJsonPedi['delivery_type'] == "retirar-na-loja"
                            _cTransp := "000030"
                        EndIf
                    EndIf

                    If !Empty(cCgc)
                        DbSelectArea("SA1")                
                        SA1->(DbSetOrder(3))
                        //Verifica se o Cliente j� est� cadastrado na SA1
                        //Caso n�o estiver, ir� cadastrar
                        If !SA1->(MsSeek(xFilial("SA1")+cCgc))
                            If CADASTRACLIENTE() != "OK" .AND. !IsBlind()
                                MsgAlert(cRet)
                            ElseIf CADASTRACLIENTE() != "OK" .AND. IsBlind()
                                FWLogMsg('INFO',, 'GERAPEDIDOS', FunName(), '', '01', cRet, 0, 0, {})
                            EndIf
                        EndIf
            
                        aPedCab:={	{"C5_TIPO" 			,"N"				,Nil},;
                                    {"C5_CLIENTE"		,SA1->A1_COD 		,Nil},;
                                    {"C5_LOJACLI"		,SA1->A1_LOJA 		,Nil},;
                                    {"C5_TABELA"		,_cCodTab 			,Nil},;
                                    {"C5_CONDPAG"		,_cCodPag  			,Nil},;
                                    {"C5_VEND1"		    ,_cVend1   			,Nil},;
                                    {"C5_DESCONT"	    ,_nVlrDescont		,Nil},;
                                    {"C5_TRANSP"	    ,_cTransp		    ,Nil},;
                                    {"C5_FRETE"	        ,_nVlrFrete		    ,Nil},;
                                    {"C5_TPFRETE"       ,'F'    		    ,Nil},;
                                    {"C5_EMISSAO"		,dDataBase			,Nil},;
                                    {"C5_XCODVND"		,cCodPedido			,Nil},;
                                    {"C5_DATA1"			,dDatabase 			,Nil}}

                        For nY := 1 To Len(oJsonPedi['items'])
                            DbSelectArea("SB1") 
                            SB1->(DbSetOrder(1))
                            
                            If !SB1->(MsSeek(xFilial("SB1")+PadR(oJsonPedi['items'][nY]['reference'],TamSx3("B2_COD")[1])))
                                MsgAlert("� necess�rio realizar o cadastro do produto "+cValToChar(oJsonPedi['items'][nY]['reference']), "PRODUTO N�O CADASTRADO")
                                //Return
                                lSB1OK := .F.                                
                            Else
                                lSB1OK := .T. 
                            Endif

                            If lSB1OK 
                                DbSelectArea("DA1")
                                DA1->(DbSetOrder(1))

                                If DA1->(MsSeek(xFilial("DA1")+_cCodTab+SB1->B1_COD))
                                    _cTES := MaTesInt(2, _cOper, SA1->A1_COD, SA1->A1_LOJA, "C", SB1->B1_COD)
                                    
                                    If Empty(_cTES )
                                        _cTES := "501"
                                    EndIf
                                    aItemPV	:= {    {"C6_ITEM" 	    ,strzero(nY,tamsx3('C6_ITEM')[1])                       ,Nil},; // Numero do Item no Pedido
                                                    {"C6_PRODUTO"	,SB1->B1_COD		                                    ,Nil},; // Codigo do Produto
                                                    {"C6_QTDVEN" 	,oJsonPedi['items'][nY]['quantity']                     ,Nil},; // Quantidade Vendida
                                                    {"C6_PRCVEN" 	,DA1->DA1_PRCVEN	 				                    ,Nil},; // Preco Unitario Liquido
                                                    {"C6_VALOR" 	,(oJsonPedi['items'][nY]['quantity']*DA1->DA1_PRCVEN)   ,Nil},; // Valor Total do Item
                                                    {"C6_LOCAL" 	,PadR(_cArmEst,tamsx3('C6_LOCAL')[1])                   ,Nil},; // Valor Total do Item
                                                    {"C6_OPER" 	    ,_cOper                                                 ,Nil},; // Opera��o
                                                    {"C6_TES" 		,_cTES 					                                ,Nil}}
                                    AADD(aPedItens,aItemPV )
                                Else
                                    _cTES := MaTesInt(2, _cOper, SA1->A1_COD, SA1->A1_LOJA, "C", SB1->B1_COD)
                                    
                                    If Empty(_cTES )
                                        _cTES := "501"
                                    EndIf

                                    aItemPV	:= {    {"C6_ITEM" 	    ,strzero(nY,tamsx3('C6_ITEM')[1])                                       ,Nil},; // Numero do Item no Pedido
                                                    {"C6_PRODUTO"	,SB1->B1_COD		                                                    ,Nil},; // Codigo do Produto
                                                    {"C6_QTDVEN" 	,oJsonPedi['items'][nY]['quantity']                                     ,Nil},; // Quantidade Vendida
                                                    {"C6_PRCVEN" 	,oJsonPedi['items'][nY]['price']	                                    ,Nil},; // Preco Unitario Liquido
                                                    {"C6_VALOR" 	,(oJsonPedi['items'][nY]['quantity']*oJsonPedi['items'][nY]['price'])   ,Nil},; // Valor Total do Item
                                                    {"C6_LOCAL" 	,PadR(_cArmEst,tamsx3('C6_LOCAL')[1])                                   ,Nil},; // Valor Total do Item
                                                    {"C6_OPER" 	    ,_cOper                                                                 ,Nil},; // Opera��o
                                                    {"C6_TES" 		,_cTES 					                                                ,Nil}}
                                    AADD(aPedItens,aItemPV )
                                EndIf
                            EndIf
                        Next nY

                        If lSB1OK
                            lMsErroAuto:=.f.
                            MSExecAuto({|x,y,z|Mata410(x,y,z)},aPedCab,aPedItens,3)

                            If lMsErroAuto
                                If !IsBlind()
                                    MostraErro()
                                Else
                                    cRet := MostraErro("/dirdoc", "error.log") // ARMAZENA A MENSAGEM DE ERRO
                                EndIf
                            Else
                                //Grava dados do pedido
                                DbSelectArea("SZ7")
                                SZ7->(DbSetOrder(1))

                                If !SZ7->(MsSeek(xFilial("SZ7")+cCodPedido))
                                    If RecLock('SZ7',.T.)
                                        SZ7->Z7_FILIAL  := xFilial("SZ7") 
                                        SZ7->Z7_CODIGO  := cCodPedido
                                        SZ7->Z7_CLIENTE := SA1->A1_COD 
                                        SZ7->Z7_LOJA    := SA1->A1_LOJA 
                                        SZ7->Z7_TABELA  := _cCodTab    
                                        SZ7->Z7_CODPAG  := _cCodPag     
                                        SZ7->Z7_VENDEDO := _cVend1       
                                        SZ7->Z7_ARMAZEM := _cArmEst
                                        SZ7->Z7_NUMSC5  := SC5->C5_NUM      
                                        SZ7->(MsUnlock())
                                    EndIf
                                    
                                    DbSelectArea("SZ8")
                                    SZ8->(DbSetOrder(1))

                                    For nZ := 1 To Len(aPedItens)
                                        If RecLock('SZ8',.T.)
                                            SZ8->Z8_FILIAL  := xFilial("SZ8")
                                            SZ8->Z8_ITEM    := aPedItens[nZ][1][2]
                                            SZ8->Z8_CODPEDI := cCodPedido
                                            SZ8->Z8_PRODUTO := aPedItens[nZ][2][2]
                                            SZ8->Z8_QTDVEN  := aPedItens[nZ][3][2]
                                            SZ8->Z8_PRCVEN  := aPedItens[nZ][4][2]
                                            SZ8->Z8_VALOR   := aPedItens[nZ][5][2]
                                            SZ8->Z8_TES     := aPedItens[nZ][8][2]
                                            SZ8->(MsUnlock())
                                        EndIf
                                    Next nZ
                                EndIf
                            EndIf
                        EndIf
                    EndIf
                EndIf
            EndIf
        Next nX

        nPage++
	Enddo
Return Nil

/*/{Protheus.doc} CriaSX1
Cria perguntas no dicionario de dados
@type function
@author  Willian Kaneta
@since   22/06/2021
@version 1.0
/*/
//-------------------------------------------------------------------

static function CriaSX1() 
  
    CPCF001(cPerg,"01","Data De ?"       ,"Data De ?"       ,"Data De ?"       , "mv_ch1"  ,"D" ,08,0,0,"G","","   ","","","mv_par01","","","","","","","","","","","","","","","","",{"","","",""},{"","","",""},{"","",""},"")
    CPCF001(cPerg,"02","Data At�?"       ,"Data At�?"       ,"Data At�?"       , "mv_ch2"  ,"D" ,08,0,0,"G","","   ","","","mv_par02","","","","","","","","","","","","","","","","",{"","","",""},{"","","",""},{"","",""},"")
    CPCF001(cPerg,"03","Tabela Pre�o?"   ,"Tabela Pre�o?"   ,"Tabela Pre�o?"   , "mv_ch3"  ,"C" ,03,0,0,"G","","DA0","","","mv_par03","","","","","","","","","","","","","","","","",{"","","",""},{"","","",""},{"","",""},"")
    CPCF001(cPerg,"04","Cond. Pagamento?","Cond. Pagamento?","Cond. Pagamento?", "mv_ch4"  ,"C" ,03,0,0,"G","","SE4","","","mv_par04","","","","","","","","","","","","","","","","",{"","","",""},{"","","",""},{"","",""},"")
    CPCF001(cPerg,"05","Vendedor?"       ,"Vendedor?"       ,"Vendedor?"       , "mv_ch5"  ,"C" ,06,0,0,"G","","SA3","","","mv_par05","","","","","","","","","","","","","","","","",{"","","",""},{"","","",""},{"","",""},"")
    CPCF001(cPerg,"06","Armazem?"        ,"Armazem?"        ,"Armazem?"        , "mv_ch6"  ,"C" ,03,0,0,"G","","NNR","","","mv_par06","","","","","","","","","","","","","","","","",{"","","",""},{"","","",""},{"","",""},"")
   
return( nil )

/*/{Protheus.doc}
@obs CPCF001
@author Willian Kaneta
@type User Function
@description Funcao para criar grupo de perguntas no mesmo molde da padrao.
@since 22/06/2021
@version Protheus 12
 
@param 01 - cGrupo  , Caracter  , Nome do grupo de pergunta.
@param 02 - cOrdem  , Caracter  , Ordem de apresentacao das perguntas na tela.
@param 03 - cPergunt , Caracter  , Texto da pergunta a ser apresentado na tela.
@param 04 - cPerSpa , Caracter  , Texto em espanhol da pergunta a ser apresentado na tela.
@param 05 - cPerEng , Caracter  , Texto em ingles da pergunta a ser apresentado na tela.
@param 06 - cVar       , Caracter  , Variavel do item.
@param 07 - cTipo      , Caracter  , Tipo do conteudo de resposta da pergunta.
@param 08 - nTamanho , Numerico  , Tamanho do campo para a resposta da pergunta.
@param 09 - nDecimal , Numerico  , Numero de casas decimais da resposta, se houver.
@param 10 - nPresel , Numerico  , Valor que define qual o item do combo estara selecionado na apresentacao da tela. Este campo somente poder� ser preenchido quando o par�metro cGSC for preenchido com "C".
@param 11 - cGSC       , Caracter  , Estilo de apresentacao da pergunta na tela: - "G" - formato que permite editar o conteudo do campo. - "S" - formato de texto que n�o permite altera��o. - "C" - formato que permite a op��o de sele��o de dados para o campo.
@param 12 - cValid  , Caracter  , Validacao do item de pergunta.
@param 13 - cF3     , Caracter  , Nome da consulta F3 que podera ser acionada pela pergunta.
@param 14 - cGrpSxg , Caracter  , Codigo do grupo de campos relacionado a pergunta.
@param 15 - cPyme      , Caracter  , Nulo
@param 16 - cVar01  , Caracter  , Nome do MV_PAR para a utilizacao nos programas.
@param 17 - cDef01  , Caracter  , Conteudo em portugues do primeiro item do objeto, caso seja Combo.
@param 18 - cDefSpa1 , Caracter  , Conteudo em espanhol do primeiro item do objeto, caso seja Combo.
@param 19 - cDefEng1 , Caracter  , Conteudo em ingles do primeiro item do objeto, caso seja Combo.
@param 20 - cCnt01  , Caracter  , Conteudo padrao da pergunta.
@param 21 - cDef02  , Caracter  , Conteudo em portugues do segundo item do objeto, caso seja Combo.
@param 22 - cDefSpa2 , Caracter  , Conteudo em espanhol do segundo item do objeto, caso seja Combo.
@param 23 - cDefEng2 , Caracter  , Conteudo em ingles do segundo item do objeto, caso seja Combo.
@param 24 - cDef03  , Caracter  , Conteudo em portugues do terceiro item do objeto, caso seja Combo.
@param 25 - cDefSpa3 , Caracter  , Conteudo em espanhol do terceiro item do objeto, caso seja Combo.
@param 26 - cDefEng3 , Caracter  , Conteudo em ingles do terceiro item do objeto, caso seja Combo.
@param 27 - cDef04  , Caracter  , Conteudo em portugues do quarto item do objeto, caso seja Combo.
@param 28 - cDefSpa4 , Caracter  , Conteudo em espanhol do quarto item do objeto, caso seja Combo.
@param 29 - cDefEng4 , Caracter  , Conteudo em ingles do quarto item do objeto, caso seja Combo.
@param 30 - cDef05  , Caracter  , Conteudo em portugues do quinto item do objeto, caso seja Combo.
@param 31 - cDefSpa5 , Caracter  , Conteudo em espanhol do quinto item do objeto, caso seja Combo.
@param 32 - cDefEng5 , Caracter  , Conteudo em ingles do quinto item do objeto, caso seja Combo.
@param 33 - aHelpPor , Vetor       , Help descritivo da pergunta em portugues.
@param 34 - aHelpEng , Vetor       , Help descritivo da pergunta em ingles.
@param 35 - aHelpSpa , Vetor       , Help descritivo da pergunta em Espanhol.
@param 36 - cHelp      , Caracter  , Nome do help equivalente, caso ja exista algum no sistema.
 
@see http://tdn.totvs.com/pages/releaseview.action?pageId=244740739
/*/
 
Static Function CPCF001( cGrupo,cOrdem,cPergunt,cPerSpa,cPerEng,cVar,cTipo ,nTamanho,nDecimal,nPresel,cGSC,cValid,cF3, cGrpSxg,cPyme,cVar01,cDef01,cDefSpa1,cDefEng1,cCnt01,cDef02,cDefSpa2,cDefEng2,cDef03,cDefSpa3,cDefEng3,cDef04,cDefSpa4,cDefEng4,cDef05,cDefSpa5,cDefEng5,aHelpPor,aHelpEng,aHelpSpa,cHelp)
 
   local aArea    := GetArea()
   local cKey
   local lPort    := .f.
   local lSpa     := .f.
   local lIngl    := .f.
   local cAlias   := "SX1"

   cKey  := "P." + AllTrim( cGrupo ) + AllTrim( cOrdem ) + "."
 
   cPyme    := Iif( cPyme       == Nil, " ", cPyme       )
   cF3      := Iif( cF3         == NIl, " ", cF3         )
   cGrpSxg  := Iif( cGrpSxg == Nil, " ", cGrpSxg         )
   cCnt01   := Iif( cCnt01      == Nil, "" , cCnt01      )
   cHelp    := Iif( cHelp        == Nil, "" , cHelp      )
 
   dbSelectArea( cAlias )
   dbSetOrder( 1 )
 
   cGrupo := PadR( cGrupo , Len( & ( SubS(cAlias,2,2) + "_GRUPO" ) ) , " " )
 
   If !( DbSeek( cGrupo + cOrdem ))
 
      cPergunt  := If(! "?" $ cPergunt .And. ! Empty(cPergunt),Alltrim(cPergunt)+" ?",cPergunt)
      cPerSpa   := If(! "?" $ cPerSpa  .And. ! Empty(cPerSpa) ,Alltrim(cPerSpa) +" ?",cPerSpa)
      cPerEng   := If(! "?" $ cPerEng  .And. ! Empty(cPerEng) ,Alltrim(cPerEng) +" ?",cPerEng)
 
      Reclock( cAlias , .T. )
 
      Replace &( SubS(cAlias,2,2) + "_GRUPO" )   With cGrupo
      Replace &( SubS(cAlias,2,2) + "_ORDEM" )  With cOrdem
      Replace &( SubS(cAlias,2,2) + "_PERGUNT" )  With cPergunt
      Replace &( SubS(cAlias,2,2) + "_PERSPA" ) With cPerSpa
      Replace &( SubS(cAlias,2,2) + "_PERENG" ) With cPerEng
      Replace &( SubS(cAlias,2,2) + "_VARIAVL" ) With cVar
      Replace &( SubS(cAlias,2,2) + "_TIPO" ) With cTipo
      Replace &( SubS(cAlias,2,2) + "_TAMANHO" ) With nTamanho
      Replace &( SubS(cAlias,2,2) + "_DECIMAL" ) With nDecimal
      Replace &( SubS(cAlias,2,2) + "_PRESEL" ) With nPresel
      Replace &( SubS(cAlias,2,2) + "_GSC" ) With cGSC
      Replace &( SubS(cAlias,2,2) + "_VALID" ) With cValid
 
      Replace &( SubS(cAlias,2,2) + "_VAR01" ) With cVar01
 
      Replace &( SubS(cAlias,2,2) + "_F3" ) With cF3
      Replace &( SubS(cAlias,2,2) + "_GRPSXG" ) With cGrpSxg
 
      If Fieldpos(SubS(cAlias,2,2) + "_PYME") > 0
         If cPyme != Nil
            Replace &( SubS(cAlias,2,2) + "_PYME" ) With cPyme
         Endif
      Endif
 
      Replace &( SubS(cAlias,2,2) + "_CNT01" )  With cCnt01
 
      If cGSC == "C"            // Mult Escolha
         Replace &( SubS(cAlias,2,2) + "_DEF01" )   With cDef01
         Replace &( SubS(cAlias,2,2) + "_DEFSPA1" ) With cDefSpa1
         Replace &( SubS(cAlias,2,2) + "_DEFENG1" ) With cDefEng1
 
         Replace &( SubS(cAlias,2,2) + "_DEF02" ) With cDef02
         Replace &( SubS(cAlias,2,2) + "_DEFSPA2" ) With cDefSpa2
         Replace &( SubS(cAlias,2,2) + "_DEFENG2" ) With cDefEng2
 
         Replace &( SubS(cAlias,2,2) + "_DEF03" ) With cDef03
         Replace &( SubS(cAlias,2,2) + "_DEFSPA3" ) With cDefSpa3
         Replace &( SubS(cAlias,2,2) + "_DEFENG3" ) With cDefEng3
 
         Replace &( SubS(cAlias,2,2) + "_DEF04" ) With cDef04
         Replace &( SubS(cAlias,2,2) + "_DEFSPA4" ) With cDefSpa4
         Replace &( SubS(cAlias,2,2) + "_DEFENG4" ) With cDefEng4
 
         Replace &( SubS(cAlias,2,2) + "_DEF05" ) With cDef05
         Replace &( SubS(cAlias,2,2) + "_DEFSPA5" ) With cDefSpa5
         Replace &( SubS(cAlias,2,2) + "_DEFENG5" ) With cDefEng5
      Endif
 
      Replace &( SubS(cAlias,2,2) + "_HELP" ) With cHelp
 
      CPCF002(cKey,aHelpPor,aHelpEng,aHelpSpa)
 
      MsUnlock()
 
   Else
 
      lPort := ! "?" $ &( SubS(cAlias,2,2) + "_PERGUNT" ) .And. ! Empty( &( SubS((cAlias)->cAlias,2,2) + "_PERGUNT" ) )
      lSpa  := ! "?" $ &( SubS(cAlias,2,2) + "_PERSPA" )  .And. ! Empty( &( SubS((cAlias)->cAlias,2,2) + "_PERSPA" ) )
      lIngl := ! "?" $ &( SubS(cAlias,2,2) + "_PERENG" )  .And. ! Empty( &( SubS((cAlias)->cAlias,2,2) + "_PERENG" ) )
 
      If lPort .Or. lSpa .Or. lIngl
         RecLock(cAlias,.F.)
         If lPort
            &( SubS((cAlias)->cAlias,2,2) + "_PERGUNT" ) := Alltrim( &( SubS((cAlias)->cAlias,2,2) + "_PERGUNT" ) ) +" ?"
         EndIf
         If lSpa
            &( SubS((cAlias)->cAlias,2,2) + "_PERSPA" ) := Alltrim( &( SubS((cAlias)->cAlias,2,2) + "_PERSPA" ) ) +" ?"
         EndIf
         If lIngl
            &( SubS((cAlias)->cAlias,2,2) + "_PERENG" ) := Alltrim( &( SubS((cAlias)->cAlias,2,2) + "_PERENG" ) ) +" ?"
         EndIf
         (cAlias)->(MsUnLock())
      EndIf
   Endif
 
   RestArea( aArea )
 
Return( Nil )


/*/{Protheus.doc} CPCF002
@author Willian Kaneta
@type User Function
@description Funcao para criar help de perguntas no mesmo molde da padrao. 
@obs #CONFIGURADOR #GENERICO #SX1
@since 22/06/2021
@version Protheus 12
 
@param cKey     , Caracter, Nome do help a ser cadastrado.
@param aHelpPor , Array   , Array com o texto do help em Portugues.
@param aHelpEng , Array   , Array com o texto do help em Ingles.
@param aHelpSpa , Array   , Array com o texto do help em Espanhol.
@param lUpd     , Boolean , Caso seja .T. e ja existir um help com o mesmo nome, atualiza o registro. Se for .F. nao atualiza.
@param cStatus  , Caracter, Parametro reservado.
 
@see http://tdn.totvs.com/display/public/PROT/PutSx1Help+-+Cadastro+de+Help
/*/
 
Static Function CPCF002(cKey,aHelpPor,aHelpEng,aHelpSpa,lUpd,cStatus)
Local cFilePor := "SIGAHLP.HLP"
Local cFileEng := "SIGAHLE.HLE"
Local cFileSpa := "SIGAHLS.HLS"
Local nRet
Local nT
Local nI
Local cLast
Local cNewMemo
Local cAlterPath := ''
Local nPos  
 
If ( ExistBlock('HLPALTERPATH') )
    cAlterPath := Upper(AllTrim(ExecBlock('HLPALTERPATH', .F., .F.)))
    If ( ValType(cAlterPath) != 'C' )
        cAlterPath := ''
    ElseIf ( (nPos:=Rat('\', cAlterPath)) == 1 )
        cAlterPath += '\'
    ElseIf ( nPos == 0  )
        cAlterPath := '\' + cAlterPath + '\'
    EndIf
     
    cFilePor := cAlterPath + cFilePor
    cFileEng := cAlterPath + cFileEng
    cFileSpa := cAlterPath + cFileSpa
     
EndIf
 
Default aHelpPor := {}
Default aHelpEng := {}
Default aHelpSpa := {}
Default lUpd     := .T.
Default cStatus  := ""
 
If Empty(cKey)
    Return
EndIf
 
If !(cStatus $ "USER|MODIFIED|TEMPLATE")
    cStatus := NIL
EndIf
 
cLast    := ""
cNewMemo := ""
                                                                                                 
nT := Len(aHelpPor)
 
For nI:= 1 to nT
   cLast := Padr(aHelpPor[nI],40)
   If nI == nT
      cLast := RTrim(cLast)
   EndIf
   cNewMemo+= cLast
Next
 
If !Empty(cNewMemo)
    nRet := SPF_SEEK( cFilePor, cKey, 1 )
    If nRet < 0
        SPF_INSERT( cFilePor, cKey, cStatus,, cNewMemo )
    Else
        If lUpd 
            SPF_DELETE( cFilePor, nRet ) 
            SPF_INSERT( cFilePor, cKey, cStatus,, cNewMemo )
        EndIf                                                           
    EndIf
EndIf
 
cLast    := ""
cNewMemo := ""
 
nT := Len(aHelpEng)
 
For nI:= 1 to nT
   cLast := Padr(aHelpEng[nI],40)
   If nI == nT
      cLast := RTrim(cLast)
   EndIf
   cNewMemo+= cLast
Next
 
If !Empty(cNewMemo)
    nRet := SPF_SEEK( cFileEng, cKey, 1 )
    If nRet < 0
        SPF_INSERT( cFileEng, cKey, cStatus,, cNewMemo )
    Else
        If lUpd
            SPF_DELETE( cFileEng, nRet ) 
            SPF_INSERT( cFileEng, cKey, cStatus,, cNewMemo )
        EndIf
    EndIf
EndIf
 
cLast    := ""
cNewMemo := ""
 
nT := Len(aHelpSpa)
 
For nI:= 1 to nT
   cLast := Padr(aHelpSpa[nI],40)
   If nI == nT
      cLast := RTrim(cLast)
   EndIf
   cNewMemo+= cLast
Next
 
If !Empty(cNewMemo)
    nRet := SPF_SEEK( cFileSpa, cKey, 1 )
    If nRet < 0
        SPF_INSERT( cFileSpa, cKey, cStatus,, cNewMemo )
    Else
        If lUpd
            SPF_DELETE( cFileSpa, nRet ) 
            SPF_INSERT( cFileSpa, cKey, cStatus,, cNewMemo )
        EndIf
    EndIf
EndIf
Return

/*/{Protheus.doc} CADASTRACLIENTE
    Fun��o para cadastrar Clientes na integra��o via API VNDA
    @type  Static Function
    @author 1.0
    @since 14/12/2021
    @version 1.0
    Obs.: Objeto Json oJsonClie private declarada na fun��o
    Principa UNIA038
/*/
Static Function CADASTRACLIENTE()
    Local aMata030It    := {}
    Local cCodCli       := GetSxENum("SA1","A1_COD")
    Local nTamNome	 	:= TamSX3("A1_NOME")[1]
    Local nTamNRed	 	:= TamSX3("A1_NREDUZ")[1]
    Local nTamLoja	 	:= TamSX3("A1_LOJA")[1]
    Local nTamCC2MUN 	:= TamSX3("CC2_MUN")[1]
    Local _cNatSA1      := SuperGetMV("MV_XNATVND",.F.,"002       ")
    Local _cCgc         := ""
    Local _cPessoa      := ""
    Local _cNomeCli     := ""
    Local _cEnderec     := ""
    Local _cTipoCli     := ""
    Local _cEstClie     := ""
    Local _cMunClie     := ""
    Local _cBairro      := ""
    Local _cCEP         := ""
    Local _cDDD         := ""
    Local _cTEL         := ""

	Private lMsErroAuto    := .F.
    
    cCodCli := GetSxENum("SA1","A1_COD")
    ConfirmSX8()

    While SA1->(MsSeek(xFilial("SA1")+cCodCli)) .Or. Empty(cCodCli)
        cCodCli := GetSxENum("SA1","A1_COD")
        ConfirmSX8()
    EndDo

    //Dados Cliente
    _cNomeCli := SUBSTR(oJsonClie['first_name'] + " "     + oJsonClie['last_name']    ,1,nTamNome)
    _cNRedCli := SUBSTR(oJsonClie['first_name'] + " "     + oJsonClie['last_name']    ,1,nTamNRed)
    _cTipoCli := "F"

    If oJsonClie['cnpj'] != Nil
        _cCgc := Padr(oJsonClie['cnpj'],TamSx3("A1_CGC")[1])
        _cPessoa := "J"
    ElseIf oJsonClie['cpf'] != Nil
        _cCgc := Padr(oJsonClie['cpf'],TamSx3("A1_CGC")[1])
        _cPessoa := "F"
    EndIf
    If Alltrim(oJsonClie['first_phone_area']) <> Nil
        _cDDD := oJsonClie['first_phone_area']
    EndIf
    If Alltrim(oJsonClie['first_phone']) <> Nil
        _cTEL := oJsonClie['first_phone']
    EndIf
    If Alltrim(oJsonClie['email']) <> Nil
        _cEmail := oJsonClie['email']
    EndIf

    //Dados Endereco Cliente
    If Alltrim(oJsonClie['recent_address']['street_name']) <> Nil
        If !Empty(oJsonClie['recent_address']['street_name'])
            _cEnderec := Alltrim(NoAcento(DecodeUtf8(oJsonClie['recent_address']['street_name'])))
        EndIf
    EndIf   
    If Alltrim(oJsonClie['recent_address']['street_number']) <> Nil
        If !Empty(oJsonClie['recent_address']['street_number'])
            _cEnderec += Alltrim(", " + oJsonClie['recent_address']['street_number'])
        EndIf
    EndIf  
    If Alltrim(oJsonClie['recent_address']['complement']) <> Nil
        If !Empty(oJsonClie['recent_address']['complement'])
            _cEnderec += Alltrim(", " + NoAcento(DecodeUtf8(oJsonClie['recent_address']['complement'])))
        EndIf
    EndIf 
    If Alltrim(oJsonClie['recent_address']['city']) <> Nil
        If !Empty(oJsonClie['recent_address']['city'])
            _cMunClie := NoAcento(DecodeUtf8( oJsonClie['recent_address']['city']))
            _cCodMuni := POSICIONE("CC2",2,xFilial("CC2")+Padr(UPPER(_cMunClie),nTamCC2MUN),"CC2_CODMUN")
            CC2->(DbCloseArea())
        EndIf
    EndIf 
    If Alltrim(oJsonClie['recent_address']['state']) <> Nil
        If !Empty(oJsonClie['recent_address']['state'])
            _cEstClie := oJsonClie['recent_address']['state']
        EndIf
    EndIf
    If Alltrim(oJsonClie['recent_address']['neighborhood']) <> Nil
        If !Empty(oJsonClie['recent_address']['neighborhood'])
            _cBairro := oJsonClie['recent_address']['neighborhood']
        EndIf
    EndIf
    If Alltrim(oJsonClie['recent_address']['zip']) <> Nil
        If !Empty(oJsonClie['recent_address']['zip'])
            _cCEP := oJsonClie['recent_address']['zip']
        EndIf
    EndIf

    //Dados Cliente
    AADD(aMata030It,{"A1_COD"       ,cCodCli                ,NIL})
    AADD(aMata030It,{"A1_LOJA"      ,STRZERO(1,nTamLoja)    ,NIL})
    AADD(aMata030It,{"A1_NOME"      ,_cNomeCli              ,NIL})
    AADD(aMata030It,{"A1_NREDUZ"    ,_cNRedCli              ,NIL})
    AADD(aMata030It,{"A1_TIPO"      ,_cTipoCli              ,NIL})
    AADD(aMata030It,{"A1_PESSOA"    ,_cPessoa               ,NIL})
    AADD(aMata030It,{"A1_EMAIL"     ,_cEmail                ,NIL})
    AADD(aMata030It,{"A1_CGC"       ,_cCgc                  ,NIL})
    AADD(aMata030It,{"A1_NATUREZ"   ,_cNatSA1               ,NIL})

    //Dados Endereco do Cliente
    If !Empty(_cEnderec)
        AADD(aMata030It,{"A1_END",_cEnderec,NIL})
    EndIf
    If !Empty(_cEstClie)
        AADD(aMata030It,{"A1_EST",_cEstClie,NIL})
    EndIf    
    If !Empty(_cCodMuni)
        AADD(aMata030It,{"A1_PAIS","105",NIL})
        AADD(aMata030It,{"A1_COD_MUN",_cCodMuni,NIL})
    EndIf   
    If !Empty(_cMunClie)
        AADD(aMata030It,{"A1_MUN",UPPER(_cMunClie),NIL})
    EndIf
    
    If !Empty(_cBairro)
        AADD(aMata030It,{"A1_BAIRRO",_cBairro,NIL})
    EndIf    
    If !Empty(_cCEP)
        AADD(aMata030It,{"A1_CEP",_cCEP,NIL})
    EndIf    
    If !Empty(_cDDD)
        AADD(aMata030It,{"A1_DDD",_cDDD,NIL})
    EndIf    
    If !Empty(_cTEL)
        AADD(aMata030It,{"A1_TEL",_cTEL,NIL})
    EndIf    
    
    MSExecAuto({|x,y| Mata030(x,y)}, aMata030It, 3) //3- Inclus�o, 4- Altera��o

    IF lMsErroAuto
        If !IsBlind()
            MostraErro()
        Else
            cRet := MostraErro("/dirdoc", "error.log") // ARMAZENA A MENSAGEM DE ERRO
        EndIf
    Else
        cRet := "OK"                        
    EndIf
Return cRet

/*/{Protheus.doc} Scheddef
    Fun��o que ir� executar ao clicar no bot�o Par�metros Schedule
    @type  Static Function
    @author 1.0
    @since 14/12/2021
    @version 1.0
/*/
Static Function Scheddef()
    Local aParam
    Local aOrd     := {}

    aParam := { "P",;                      //Tipo R para relatorio P para processo   
                "UNIA038",;// Pergunte do relatorio, caso nao use passar ParamDef            
                "sz7",;  // Alias            
                aOrd,;   //Array de ordens   
                "Parametros SchedDef"}    

Return aParam
