#Include "protheus.ch"
/*/{Protheus.doc} User Function UNIA040
    Informar dados referente a expedicao que devem ser impressos na Nota Fiscal
    @type  Function
    @author Original - Sergio S. Fuzinaka - 14/12/2005 | Modificado - Denis Rodrigues - 16/12/2020
    Modificado - Daniel Barcelos - 04-01-2021
    @since 16/12/2020
    @version version
            2,0
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
User Function UNIA040() 

    //+--------------------------------------------------------------+
    //| Define Array contendo as Rotinas a executar do programa      |
    //| ----------- Elementos contidos por dimensao ------------     |
    //| 1. Nome a aparecer no cabecalho                              |
    //| 2. Nome da Rotina associada                                  |
    //| 3. Usado pela rotina                                         |
    //| 4. Tipo de Transa‡„o a ser efetuada                          |
    //|    1 - Pesquisa e Posiciona em um Banco de Dados             |
    //|    2 - Simplesmente Mostra os Campos                         |
    //|    3 - Inclui registros no Bancos de Dados                   |
    //|    4 - Altera o registro corrente                            |
    //|    5 - Remove o registro corrente do Banco de Dados          |
    //+--------------------------------------------------------------+
    Private aRotina	:= { { OemtoAnsi("Pesquisar") , "AxPesqui"    , 0 , 1},;
                        { OemtoAnsi("Visualizar") , "AxVisual"    , 0 , 2},;  
                        { OemtoAnsi("Manutencao") , "U_UNIA041"   , 0 , 4},;  
                        { 'Legenda'			      , 'U_UNIA040LEG' , 0 , 2 } }

    Private cCadastro	:= OemtoAnsi("Expedição")         

    dbSelectArea("SF2")
    dbSetOrder(1)

    mBrowse( 06, 01, 22, 75, 'SF2',,,,,, U_UNIA040LEG() )

Return Nil

/*/{Protheus.doc} UNIA041
    Inclusão ou alteração de Transportadora e Veiculo
    @type  Static Function
    @author Original - Sergio S. Fuzinaka - 14/12/2005 | Modificado - Denis Rodrigues - 16/12/2020
    @since 16/12/2020
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example (examples)
    @see (links_or_references)
/*/
User Function UNIA041()

    Local aArea		:= GetArea()
    Local aTitles	:= {"Nota Fiscal", "Volumes"}
    Local nCntFor	:= 0
    Local nOpc		:= 0
    Local lVeiculo	:= (SF2->(FieldPos("F2_VEICUL1"))>0 .And. SF2->(FieldPos("F2_VEICUL2"))>0 .And. SF2->(FieldPos("F2_VEICUL3"))>0)
    Local cTransp	:= ""
    Local cVeicul1	:= ""
    Local cVeicul2	:= ""
    Local cVeicul3	:= ""
    Local oDlg
    Local oFolder
    Local oList

    Private aHeader	  := {}
    Private aCols	  := {}
    Private oTransp
    Private oVeicul1
    Private oVeicul2
    Private oVeicul3

    If lVeiculo

        RegToMemory("SF2",.F.)
        
        cTransp	:= Posicione("SA4",1,xFilial("SA4")+SF2->F2_TRANSP,"A4_NOME")
        cVeicul1:= Posicione("DA3",1,xFilial("DA3")+SF2->F2_VEICUL1,"DA3_DESC")
        cVeicul2:= Posicione("DA3",1,xFilial("DA3")+SF2->F2_VEICUL2,"DA3_DESC")	
        cVeicul3:= Posicione("DA3",1,xFilial("DA3")+SF2->F2_VEICUL3,"DA3_DESC")

        //+---------------------+
        //| Montagem do aHeader |
        //+---------------------+
        cQuery := " SELECT X3_TITULO AS X3TITULO,"
        cQuery += " X3_CAMPO AS X3CAMPO,"
        cQuery += " X3_PICTURE AS X3PICTURE,"
        cQuery += " X3_TAMANHO AS X3TAMANHO,"
        cQuery += " X3_DECIMAL AS X3DECIMAL,"
        cQuery += " X3_VALID AS X3VALID,"
        cQuery += " X3_USADO AS X3USADO,"
        cQuery += " X3_TIPO AS X3TIPO,"
        cQuery += " X3_ARQUIVO AS X3ARQUIVO,"
        cQuery += " X3_F3 AS X3F3,"
        cQuery += " X3_CONTEXT AS X3CONTEXT,"
        cQuery += " X3_NIVEL AS X3NIVEL,"
        cQuery += " X3_VLDUSER AS X3VLDUSER,"
        cQuery += " X3_VISUAL AS X3VISUAL"
        cQuery += " FROM " + RetSQLName("SX3")
        cQuery += " WHERE X3_ARQUIVO = 'SF2'"
        cQuery += " ORDER BY X3_ORDEM"
        cQuery := ChangeQuery(cQuery)
        dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasT := GetNextAlias(),.F.,.T. )

        While ( cAliasT )->( !Eof() )

            If ( X3USO(( cAliasT )->X3USADO) .And. AllTrim(( cAliasT )->X3CAMPO) $ "F2_DOC|F2_SERIE|F2_CLIENTE|F2_LOJA|F2_EMISSAO" .And. ;
                cNivel >= ( cAliasT )->X3NIVEL )

                aAdd(aHeader,{  ( cAliasT )->X3TITULO,;
                                ( cAliasT )->X3CAMPO,;
                                ( cAliasT )->X3PICTURE,;
                                ( cAliasT )->X3TAMANHO,;
                                ( cAliasT )->X3DECIMAL,;
                                ( cAliasT )->X3VALID,;
                                ( cAliasT )->X3USADO,;
                                ( cAliasT )->X3TIPO,;
                                ( cAliasT )->X3ARQUIVO,;
                                ( cAliasT )->X3CONTEXT } )
            EndIf

            ( cAliasT )->( dbSkip() )

        EndDo

        ( cAliasT )->(dbCloseArea())                    
	
        dbSelectArea("SF2")
        aAdd(aCols,Array(Len(aHeader)))
        For nCntFor:=1 To Len(aHeader)
            If ( aHeader[nCntFor,10] <>  "V" )
                aCols[Len(aCols)][nCntFor] := FieldGet(FieldPos(aHeader[nCntFor,2]))
            Else			
                aCols[Len(aCols)][nCntFor] := CriaVar(aHeader[nCntFor,2])
            EndIf
        Next nCntFor
	
        DEFINE MSDIALOG oDlg TITLE OemToAnsi("Manutencao de Transportadoras e Veiculos") FROM 09,00 TO 28.2,80 //"Manutencao de Transportadoras e Veiculos"
        
        oFolder	:= TFolder():New(001,001,aTitles,{"HEADER", "VOLUMES"},oDlg,,,, .T., .F.,315,141)
        oList 	:= TWBrowse():New( 5, 1, 310, 42,,{aHeader[1,1],aHeader[2,1],aHeader[3,1],aHeader[4,1],aHeader[5,1]},{30,90,50,30,50},oFolder:aDialogs[1],,,,,,,,,,,,.F.,,.T.,,.F.,,, ) //"Numero"###"Serie"###"Cliente"###"Loja"###"DT Emissao"
        oList:SetArray(aCols)
        oList:bLine	:= {|| {aCols[oList:nAt][1],aCols[oList:nAt][2],aCols[oList:nAt][3],aCols[oList:nAt][4],aCols[oList:nAt][5]}}
        oList:lAutoEdit	:= .F.
        
        @ 051,005 SAY RetTitle("F2_TRANSP")		SIZE 40,10 PIXEL OF oFolder:aDialogs[1]
        @ 066,005 SAY RetTitle("F2_VEICUL1")	SIZE 40,10 PIXEL OF oFolder:aDialogs[1]
        @ 081,005 SAY RetTitle("F2_VEICUL2")	SIZE 40,10 PIXEL OF oFolder:aDialogs[1]	
        @ 095,005 SAY RetTitle("F2_VEICUL3")	SIZE 40,10 PIXEL OF oFolder:aDialogs[1]		
        
        @ 051,050 MSGET M->F2_TRANSP	PICTURE PesqPict("SF2","F2_TRANSP")		F3 CpoRetF3("F2_TRANSP")	SIZE 50,07 PIXEL OF oFolder:aDialogs[1] VALID IIf(Vazio(),(cTransp:="",.T.),.F.) .Or. (ExistCpo("SA4").And.A120Disp(@cTransp))
        @ 066,050 MSGET M->F2_VEICUL1	PICTURE PesqPict("SF2","F2_VEICUL1")	F3 CpoRetF3("F2_VEICUL1")	SIZE 50,07 PIXEL OF oFolder:aDialogs[1] VALID IIf(Vazio(),(cVeicul1:="",.T.),.F.) .Or. (ExistCpo("DA3").And.A120Disp(@cVeicul1))
        @ 081,050 MSGET M->F2_VEICUL2	PICTURE PesqPict("SF2","F2_VEICUL2")	F3 CpoRetF3("F2_VEICUL2")	SIZE 50,07 PIXEL OF oFolder:aDialogs[1] VALID IIf(Vazio(),(cVeicul2:="",.T.),.F.) .Or. (ExistCpo("DA3").And.A120Disp(@cVeicul2))	
        @ 095,050 MSGET M->F2_VEICUL3	PICTURE PesqPict("SF2","F2_VEICUL3")	F3 CpoRetF3("F2_VEICUL3")	SIZE 50,07 PIXEL OF oFolder:aDialogs[1] VALID IIf(Vazio(),(cVeicul3:="",.T.),.F.) .Or. (ExistCpo("DA3").And.A120Disp(@cVeicul3))	
        
        @ 051,105 MSGET oTransp		VAR cTransp		PICTURE PesqPict("SF2","F2_TRANSP")		WHEN .F. SIZE 150,07 PIXEL OF oFolder:aDialogs[1]
        @ 066,105 MSGET oVeicul1	VAR cVeicul1	PICTURE PesqPict("SF2","F2_VEICUL1")	WHEN .F. SIZE 150,07 PIXEL OF oFolder:aDialogs[1]
        @ 081,105 MSGET oVeicul2	VAR cVeicul2	PICTURE PesqPict("SF2","F2_VEICUL2")	WHEN .F. SIZE 150,07 PIXEL OF oFolder:aDialogs[1]	
        @ 095,105 MSGET oVeicul3	VAR cVeicul3	PICTURE PesqPict("SF2","F2_VEICUL3")	WHEN .F. SIZE 150,07 PIXEL OF oFolder:aDialogs[1]		

        // folder VOLUMES
        @ 005,005 SAY RetTitle("F2_ESPECI1")	SIZE 40,10 PIXEL OF oFolder:aDialogs[2]
        @ 020,005 SAY RetTitle("F2_ESPECI2")	SIZE 40,10 PIXEL OF oFolder:aDialogs[2]
        @ 035,005 SAY RetTitle("F2_ESPECI3")	SIZE 40,10 PIXEL OF oFolder:aDialogs[2]	
        @ 050,005 SAY RetTitle("F2_ESPECI4")	SIZE 40,10 PIXEL OF oFolder:aDialogs[2]		
        @ 005,050 MSGET M->F2_ESPECI1	PICTURE PesqPict("SF2","F2_ESPECI1")	SIZE 50,07 PIXEL OF oFolder:aDialogs[2] 
        @ 020,050 MSGET M->F2_ESPECI2	PICTURE PesqPict("SF2","F2_ESPECI2")	SIZE 50,07 PIXEL OF oFolder:aDialogs[2] 
        @ 035,050 MSGET M->F2_ESPECI3	PICTURE PesqPict("SF2","F2_ESPECI3")	SIZE 50,07 PIXEL OF oFolder:aDialogs[2] 
        @ 050,050 MSGET M->F2_ESPECI4	PICTURE PesqPict("SF2","F2_ESPECI4")	SIZE 50,07 PIXEL OF oFolder:aDialogs[2] 
        
        @ 005,105 SAY RetTitle("F2_VOLUME1")	SIZE 40,10 PIXEL OF oFolder:aDialogs[2]
        @ 020,105 SAY RetTitle("F2_VOLUME2")	SIZE 40,10 PIXEL OF oFolder:aDialogs[2]
        @ 035,105 SAY RetTitle("F2_VOLUME3")	SIZE 40,10 PIXEL OF oFolder:aDialogs[2]	
        @ 050,105 SAY RetTitle("F2_VOLUME4")	SIZE 40,10 PIXEL OF oFolder:aDialogs[2]		
        @ 005,150 MSGET M->F2_VOLUME1	PICTURE PesqPict("SF2","F2_VOLUME1")	SIZE 50,07 PIXEL OF oFolder:aDialogs[2] 
        @ 020,150 MSGET M->F2_VOLUME2	PICTURE PesqPict("SF2","F2_VOLUME2")	SIZE 50,07 PIXEL OF oFolder:aDialogs[2] 
        @ 035,150 MSGET M->F2_VOLUME3	PICTURE PesqPict("SF2","F2_VOLUME3")	SIZE 50,07 PIXEL OF oFolder:aDialogs[2] 
        @ 050,150 MSGET M->F2_VOLUME4	PICTURE PesqPict("SF2","F2_VOLUME4")	SIZE 50,07 PIXEL OF oFolder:aDialogs[2] 

        @ 005,205 SAY RetTitle("F2_PLIQUI")	SIZE 40,10 PIXEL OF oFolder:aDialogs[2]
        @ 020,205 SAY RetTitle("F2_PBRUTO")	SIZE 40,10 PIXEL OF oFolder:aDialogs[2]
        @ 005,250 MSGET M->F2_PLIQUI	PICTURE PesqPict("SF2","F2_PLIQUI")	SIZE 50,07 PIXEL OF oFolder:aDialogs[2] 
        @ 020,250 MSGET M->F2_PBRUTO	PICTURE PesqPict("SF2","F2_PBRUTO")	SIZE 50,07 PIXEL OF oFolder:aDialogs[2] 

        @ 110,005 TO 111,310 PIXEL OF oFolder:aDialogs[1]  // linha separadora

        @ 125,225 BUTTON OemToAnsi("Confirmar")	SIZE 040,13 FONT oDlg:oFont ACTION (nOpc:=1,oDlg:End())	OF oDlg PIXEL	//"Confirmar"
        @ 125,270 BUTTON OemToAnsi("Cancelar")	SIZE 040,13 FONT oDlg:oFont ACTION oDlg:End()			OF oDlg PIXEL	//"Cancelar"
        
        ACTIVATE MSDIALOG oDlg CENTERED
        
        If nOpc == 1

            RecLock("SF2",.F.)        
                SF2->F2_TRANSP	:= M->F2_TRANSP
                SF2->F2_VEICUL1	:= M->F2_VEICUL1
                SF2->F2_VEICUL2	:= M->F2_VEICUL2		
                SF2->F2_VEICUL3	:= M->F2_VEICUL3
                SF2->F2_ESPECI1	:= M->F2_ESPECI1
                SF2->F2_ESPECI2	:= M->F2_ESPECI2
                SF2->F2_ESPECI3	:= M->F2_ESPECI3
                SF2->F2_ESPECI4	:= M->F2_ESPECI4 
                SF2->F2_VOLUME1	:= M->F2_VOLUME1
                SF2->F2_VOLUME2	:= M->F2_VOLUME2
                SF2->F2_VOLUME3	:= M->F2_VOLUME3
                SF2->F2_VOLUME4 := M->F2_VOLUME4
                //SF2->F2_PLIQUI 	:= (M->F2_PBRUTO * 0.95) Solicitado Alceu 15/02/21
                SF2->F2_PLIQUI 	:= M->F2_PLIQUI
                SF2->F2_PBRUTO 	:= M->F2_PBRUTO
            MsUnlock()

        Endif 
	
    Else
	    MsgAlert(OemToAnsi("Campo nao existe: " + "F2_VEICUL1 / F2_VEICUL2 / F2_VEICUL3"))
    EndIf 

    RestArea(aArea) 

Return Nil 

/*/{Protheus.doc} User Function A120Disp
    Display do Campo
    @type  Function
    @author Original - Sergio S. Fuzinaka - 14/12/2005 | Modificado - Denis Rodrigues - 16/12/2020
    @since 16/12/2020
    @version version
    @param param_name, param_type, param_descr
               cCampo, String    , Nome do campo
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
Static Function A120Disp(cCampo)

    Local aArea	:= GetArea()
    Local cCpo	:= ReadVar()

    Do Case
        Case cCpo == "M->F2_TRANSP"
            cCampo := Posicione("SA4",1,xFilial("SA4")+M->F2_TRANSP,"A4_NOME")
            oTransp:Refresh()
        Case cCpo == "M->F2_VEICUL1"
            cCampo	:= Posicione("DA3",1,xFilial("DA3")+M->F2_VEICUL1,"DA3_DESC")
            oVeicul1:Refresh()	
        Case cCpo == "M->F2_VEICUL2"
            cCampo	:= Posicione("DA3",1,xFilial("DA3")+M->F2_VEICUL2,"DA3_DESC")
            oVeicul2:Refresh()	
        Otherwise
            cCampo	:= Posicione("DA3",1,xFilial("DA3")+M->F2_VEICUL3,"DA3_DESC")
            oVeicul3:Refresh()	
    EndCase

    RestArea(aArea)

Return(.T.)

/*/{Protheus.doc} UNIA040LEG
    Legenda da Rotina UNIA040
    @type  Static Function
    @author Denis Rodrigues
    @since 16/12/2020
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example (examples)
    @see (links_or_references)
/*/
User Function UNIA040LEG( nReg )

    Local aLegenda
    Local uRetorno := .t.

    aLegenda	:= {{ 'BR_VERMELHO'	, 'Aguardando informação de Peso' },;
                    { 'BR_VERDE'	, 'Peso já informado' }}

    If nReg = Nil

        uRetorno	:= {{ 'Empty(SF2->F2_ESPECI1) .or. Empty(SF2->F2_VOLUME1) .or. SF2->F2_PLIQUI == 0 .or. SF2->F2_PBRUTO == 0', aLegenda[ 1, 1 ] }, ;
                        { '!Empty(SF2->F2_ESPECI1) .and. !Empty(SF2->F2_VOLUME1) .and. SF2->F2_PLIQUI > 0 .and. SF2->F2_PBRUTO > 0', aLegenda[ 2, 1 ] }}
    Else
        BrwLegenda( cCadastro, 'Legenda', aLegenda )
    EndIf

Return( uRetorno )
