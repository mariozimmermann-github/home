
#include 'topconn.ch'
#include "totvs.ch"
#include "TBICONN.CH"
#include "TOTVSWebSrv.ch"

/*/{Protheus.doc} User Function UNIA038
    Rotina para executar a integração via API VNDA - Atualiza os saldos Produtos no e-Commerce
    @type  Function
    @author 1.0
    @since 10/12/2021
    @version 1.0
    @see (links_or_references)
    /*/
User Function UNIA039()
    Private oJsonVariant  := JsonObject():new()
    Private oJsonProdAll  := JsonObject():new()
    Private oJsonProduto  := JsonObject():new()
    Private oBodyVar      := JsonObject():New()

    If !IsBlind()
        INTEGRAMENU()   
    Else
        INTREGAJOB()
    EndIf    
Return 

/*/{Protheus.doc} INTEGRAMENU
    Integração API Pedidos VNDA via menu
    @type  Static Function
    @author Willian Kaneta
    @since 16/12/2021
    @version 1.0
/*/
Static Function INTEGRAMENU()
    Private cPerg   	   := "UNIA039"

    If Alltrim(cFilAnt) == "0101"
        CriaSX1()

        If !Pergunte(cPerg,.T.)
            Return Nil
        EndIf
        
        If !Empty(MV_PAR01)
            FWMsgRun(, {|| UPDSALDOS() }, 'Processando', 'Atualizando os saldos dos Produtos no E-commerce VNDA...' )
        Else
            MsgAlert("É obrigatório informar o local de estoque!!", "Atenção")
        EndIf
    Else
        MsgAlert("Acessar a filial 0101!!", "Atenção")
    EndIf

    MsgInfo("Atualização finalizada...Verificar!")
Return Nil

/*/{Protheus.doc} INTREGAJOB
    Integração API Pedidos VNDA via Schedule
    @type  Static Function
    @author Willian Kaneta
    @since 16/12/2021
    @version 1.0
/*/
Static Function INTREGAJOB()

    PREPARE ENVIRONMENT EMPRESA "01" FILIAL "0101"

        UPDSALDOS()

    RESET ENVIRONMENT

Return Nil

/*/{Protheus.doc} User Function UPDSALDOS
    Atualiza os saldos dos produtos via API VNDA
    @type  Function
    @author Willian Kaneta
    @since 13/12/2021
    @version 1.0
    /*/
Static Function UPDSALDOS()
    Local cUrlAPI       := Alltrim(supergetmv('MV_XURLVNDA',.f.,'https://selecionadosuniagro.vnda.com.br/api/v2' ))
    Local cApiKey       := Alltrim(supergetmv('MV_XAPIKEY',.f.,'Bearer 7LnuAcermCWVuf1nuVEgprP2' ))
    Local nTimeOut      := 120
    Local nX,nY         := 0
    Local nPage         := 1
	Local nTotPages     := 1
    Local aHeader       := {}
    Local cHeadRet1     := ""
    Local cHeadRet2     := ""
    Local cErro         := ""
    Local nCodSB1       := ""
    Local cIdProd       := ""
    Local nIdProd       := 0
    Local nIdVarian     := 0

    Private lMsErroAuto := .F.
    Private _cCodTab    := PadR(MV_PAR03,tamsx3('DA0_CODTAB')[1])
    Private _cCodPag    := MV_PAR04
    Private _cVend1     := MV_PAR05
    Private _cArmEst    := MV_PAR06

    aadd(aHeader,'Authorization: '+cApiKey)

    While nPage <= nTotPages

        cRet:= HttpGet(cUrlAPI+'/products',"per_page=50"+'&page='+Alltrim(cValToChar(nPage)),nTimeOut,aHeader,@cHeadRet1)

        If Empty(cRet)
            If !IsBlind()
                Alert("Nenhum dado retornado pela integração")
            EndIf
            return
        Endif
        
        cErro := oJsonProdAll:fromJSON( cRet )

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
        
        For nX := 1 To Len(oJsonProdAll)
            If oJsonProdAll[nX]['active']
                oJsonProduto  := oJsonProdAll[nX]
                nIdProd  := oJsonProduto['id']
                cIdProd  := cValToChar(nIdProd)
                For nY := 1 To Len(oJsonProduto['variants'])
                    nIdVarian   := oJsonProduto["variants"][nY][cIdProd]["id"]
                    nCodSB1     := oJsonProduto["variants"][nY][cIdProd]["sku"]

                    DbSelectArea("SB2")
                    SB2->(DbSetOrder(1))

                    If SB2->(MsSeek(xFilial("SB1")+Padr(nCodSB1,TamSx3("B2_COD")[1])+MV_PAR01))
                        oBodyVar['sku']         := nCodSB1
                        oBodyVar['quantity']    := SB2->B2_QATU
                        cBody := EncodeUTF8( oBodyVar:ToJson() )
                        HTTPQuote( cUrlAPI+"/products/"+cIdProd+"/variants/"+nIdVarian,;
                                   "PATCH",,cBody,nTimeOut,aHeader,@cHeadRet2)
                    EndIf
                Next nY
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
  
    CPCF001(cPerg,"01","Local Estoque?"        ,"Local Estoque?"        ,"Local Estoque?"        , "mv_ch1"  ,"C" ,03,0,0,"G","","NNR","","","mv_par01","","","","","","","","","","","","","","","","",{"","","",""},{"","","",""},{"","",""},"")
   
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
@param 10 - nPresel , Numerico  , Valor que define qual o item do combo estara selecionado na apresentacao da tela. Este campo somente poder ser preenchido quando o parmetro cGSC for preenchido com "C".
@param 11 - cGSC       , Caracter  , Estilo de apresentacao da pergunta na tela: - "G" - formato que permite editar o conteudo do campo. - "S" - formato de texto que no permite alterao. - "C" - formato que permite a opo de seleo de dados para o campo.
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
