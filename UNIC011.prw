//Bibliotecas
#Include "Totvs.ch"
#Include "FWMVCDef.ch"

/*/{Protheus.doc} User Function UNIA011
Saldos Produtos X Televendas Callcenter
@author Willian Kaneta
@since 26/11/2021
@version 1.0
@type function
/*/

User Function UNIC011() 
	Local aArea   := GetArea()
	Local oBrowse
	Local nIgnore := 1
    

	Private aRotina := {}

	//Definicao do menu
	aRotina := MenuDef()

	//Instanciando o browse
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("SZ3")
    oBrowse:SetDescription("UNIAGRO")

	//Ativa a Browse
	oBrowse:Activate()

	//Tratativa para ignorar warnings de ViewDef e ModelDef nunca chamados
	If nIgnore == 0
		ModelDef()
		ViewDef() 
	EndIf 

	RestArea(aArea)
Return Nil

/*/{Protheus.doc} MenuDef
Menu de opcoes na funcao UNIA011
@author Willian Kaneta
@since 26/11/2021
@version 1.0
@type function
/*/
Static Function MenuDef()
	Local aRotina := {}

	//Adicionando opcoes do menu
	ADD OPTION aRotina TITLE "Visualizar"           ACTION "VIEWDEF.UNIC011"         OPERATION 1 ACCESS 0
	ADD OPTION aRotina TITLE "Incluir"              ACTION "VIEWDEF.UNIC011"         OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE "Alterar"              ACTION "VIEWDEF.UNIC011"         OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Excluir"              ACTION "VIEWDEF.UNIC011"         OPERATION 5 ACCESS 0

Return aRotina
 
/*/{Protheus.doc} ModelDef
Modelo de dados na funcao UNIA011
@author Willian Kaneta
@since 26/11/2021
@version 1.0
@type function
/*/
Static Function ModelDef()
	Local oStrCab   := FWFormStruct(1, "SZ3")
	Local oStrGrid1 := FWFormStruct(1, "SZ4")
	Local oStrGrid2 := FWFormStruct(1, "SZ5")
	Local oStrGrid3 := FWFormStruct(1, "SZ6")
    Local oStrTMP1	:= FWFormModelStruct():New()
    Local oStrTMP2	:= FWFormModelStruct():New() 
	Local oModel
	Local bPre      := Nil
	Local bPos      := Nil
	Local bCommit   := Nil
	Local bCancel   := Nil  

	//Cria o modelo de dados para cadastro
	oModel := MPFormModel():New("UNIA011M", bPre, bPos, bCommit, bCancel)
    
    //Remove os campos da grid POA
    //Deixa os campos somente pertecente a 
    //Filial de POA
    oStrGrid1:RemoveField( "Z4_SUAPOA"  ) 

    //Remove os campos da grid Cachoerinha
    //Deixa os campos somente pertecente a 
    //Filial de cachoerinha
    oStrGrid2:RemoveField( "Z5_CODIGO"  )  
    oStrGrid2:RemoveField( "Z5_SUACHAC" )

    //Remove os campos da grid Itajaí
    //Deixa os campos somente pertecente a 
    //Filial de Itajaí
    oStrGrid3:RemoveField( "Z6_CODIGO"  )    
    oStrGrid3:RemoveField( "Z6_SUAITAJ" )   

    //Adiciona campo virtual
    oStrTMP1:AddField( ;                         // Ord. Tipo Desc.
            RetTitle("B1_DESC")           , ;   // [01]  C   Titulo do campo
            RetTitle("B1_DESC")           , ;   // [02]  C   ToolTip do campo
            "TMP1_DESC"                   , ;   // [03]  C   Id do Field
            'C'                           , ;   // [04]  C   Tipo do campo
            TamSX3("B1_DESC")[1]          , ;   // [05]  N   Tamanho do campo
            0                             , ;   // [06]  N   Decimal do campo
            NIL                           , ;   // [07]  B   Code-block de validação do campo
            { || .T. }                    , ;   // [08]  B   Code-block de validação When do campo
            NIL                           , ;   // [09]  A   Lista de valores permitido do campo
            NIL                           , ;   // [10]  L   Indica se o campo tem preenchimento obrigatório
            FwBuildFeature( STRUCT_FEATURE_INIPAD,"" ), ;   // [11]  B   Code-block de inicializacao do campo
            NIL                           , ;   // [12]  L   Indica se trata-se de um campo chave
            NIL                           , ;   // [13]  L   Indica se o campo pode receber valor em uma operação de update.
            .T.                           )     // [14]  L   Indica se o campo é virtual
    
    oStrTMP2:AddField( ;                         // Ord. Tipo Desc.
        RetTitle("B1_COD")           , ;   // [01]  C   Titulo do campo
        RetTitle("B1_COD")           , ;   // [02]  C   ToolTip do campo
        "TMP2_COD"                    , ;   // [03]  C   Id do Field
        'C'                           , ;   // [04]  C   Tipo do campo
        TamSX3("B1_COD")[1]          , ;   // [05]  N   Tamanho do campo
        0                             , ;   // [06]  N   Decimal do campo
        NIL                           , ;   // [07]  B   Code-block de validação do camp
        NIL                           , ;   // [08]  B   Code-block de validação When do
        NIL                           , ;   // [09]  A   Lista de valores permitido do c
        NIL                           , ;   // [10]  L   Indica se o campo tem preenchim
        FwBuildFeature( STRUCT_FEATURE_INIPAD,"" ), ;   // [11]  B   Code-block de inicializacao do 
        NIL                           , ;   // [12]  L   Indica se trata-se de um campo 
        NIL                           , ;   // [13]  L   Indica se o campo pode receber 
        .T.                           )     // [14]  L   Indica se o campo é virtual

    oStrTMP2:AddField( ;                         // Ord. Tipo Desc.
        RetTitle("B1_DESC")           , ;   // [01]  C   Titulo do campo
        RetTitle("B1_DESC")           , ;   // [02]  C   ToolTip do campo
        "TMP2_DESC"                    , ;   // [03]  C   Id do Field
        'C'                           , ;   // [04]  C   Tipo do campo
        TamSX3("B1_DESC")[1]          , ;   // [05]  N   Tamanho do campo
        0                             , ;   // [06]  N   Decimal do campo
        NIL                           , ;   // [07]  B   Code-block de validação do camp
        NIL                           , ;   // [08]  B   Code-block de validação When do
        NIL                           , ;   // [09]  A   Lista de valores permitido do c
        NIL                           , ;   // [10]  L   Indica se o campo tem preenchim
        FwBuildFeature( STRUCT_FEATURE_INIPAD,"" ), ;   // [11]  B   Code-block de inicializacao do 
        NIL                           , ;   // [12]  L   Indica se trata-se de um campo 
        NIL                           , ;   // [13]  L   Indica se o campo pode receber 
        .T.                           )     // [14]  L   Indica se o campo é virtual 

    oStrTMP2:AddField( ;                         // Ord. Tipo Desc.
        RetTitle("B1_LOCPAD")         , ;   // [01]  C   Titulo do campo
        RetTitle("B1_LOCPAD")         , ;   // [02]  C   ToolTip do campo
        "TMP2_LOCAL"                  , ;   // [03]  C   Id do Field
        'C'                           , ;   // [04]  C   Tipo do campo
        TamSX3("B1_LOCPAD")[1]        , ;   // [05]  N   Tamanho do campo
        0                             , ;   // [06]  N   Decimal do campo
        NIL                           , ;   // [07]  B   Code-block de validação do cam
        NIL                           , ;   // [08]  B   Code-block de validação When d
        NIL                           , ;   // [09]  A   Lista de valores permitido do 
        NIL                           , ;   // [10]  L   Indica se o campo tem preenchi
        FwBuildFeature( STRUCT_FEATURE_INIPAD,"" ), ;   // [11]  B   Code-block de inic
        NIL                           , ;   // [12]  L   Indica se trata-se de um campo
        NIL                           , ;   // [13]  L   Indica se o campo pode receber
        .T.                           )     // [14]  L   Indica se o campo é virtual

    oStrTMP1:AddTrigger( 'TMP1_DESC', 'TMP1_DESC', , { || RETPRODUT() } )	
    oStrTMP1:AddTrigger( 'Z3_CLIENTE', 'Z3_LOJA' , , { || RETPRODUT() } )	 

    //Cria os modelos, um cabeçalho e 3 grids
	oModel:AddFields("SZ3MASTER", /*cOwner*/    ,oStrCab  ) 
	oModel:AddGrid('SZ4GRID1'   ,'SZ3MASTER'    ,oStrGrid1)
	oModel:AddGrid('SZ5GRID1'   ,'SZ3MASTER'    ,oStrGrid2)
	oModel:AddGrid('SZ6GRID1'   ,'SZ3MASTER'    ,oStrGrid3) 

    //Estrutura para a parte da pesquisa do produto
    oModel:AddFields("TMPCABEC"  ,"SZ3MASTER"   ,oStrTMP1 )
	oModel:AddGrid( "TMPGRID1"   ,"SZ3MASTER"   ,oStrTMP2 )

    //Adiciona a chave primária - indice da tabela SZ3
    oModel:SetPrimaryKey( { 'Z3_FILIAL','Z3_CODIGO','Z3_CLIENTE','Z3_LOJA'} )

    //Relaciona as grids com a chave primária da tabela SZ3
    oModel:SetRelation( "SZ4GRID1", { { "Z4_FILIAL" , "xFilial('SZ4')"  },;
                                      { "Z4_CODIGO" , "Z3_CODIGO"       } },SZ4->( IndexKey( 1 ) ) )

    oModel:SetRelation( "SZ5GRID1", { { "Z5_FILIAL" , "xFilial('SZ5')"  },;
                                      { "Z5_CODIGO" , "Z3_CODIGO"       } },SZ5->( IndexKey( 1 ) ) )

    oModel:SetRelation( "SZ6GRID1", { { "Z6_FILIAL" , "xFilial('SZ6')"  },;
                                      { "Z6_CODIGO" , "Z3_CODIGO"       } },SZ6->( IndexKey( 1 ) ) )                                      
    
    oModel:SetDescription("Uniagro")
    oModel:GetModel("SZ3MASTER"):SetDescription("Dados Cliente")
    oModel:GetModel("SZ4GRID1"):SetDescription("POA")    
    oModel:GetModel("SZ5GRID1"):SetDescription("Cachoerinha")    
    oModel:GetModel("SZ6GRID1"):SetDescription("Itajaí")    
    oModel:GetModel("TMPCABEC"):SetDescription("Produto")    
    oModel:GetModel("TMPGRID1"):SetDescription("Dados Produto")    

    oModel:getModel('TMPCABEC'):SetOptional(.F.) 
    oModel:getModel('TMPGRID1'):SetOptional(.T.)
    oModel:GetModel("TMPGRID1"):SetOnlyQuery(.T.)
   
Return oModel  

/*/{Protheus.doc} ViewDef
Visualizacao de dados na funcao UNIA011
@author Willian Kaneta
@since 26/11/2021
@version 1.0
@type function
/*/
Static Function ViewDef() 
	Local oModel    := FWLoadModel("UNIC011") 
	Local oStrCab   := FWFormStruct(2, "SZ3")
	Local oStrGrid1 := FWFormStruct(2, "SZ4")
	Local oStrGrid2 := FWFormStruct(2, "SZ5")
	Local oStrGrid3 := FWFormStruct(2, "SZ6")
    Local oViewTMP1 := FWFormViewStruct():New()
    Local oViewTMP2 := FWFormViewStruct():New() 
	Local oView

	//Cria a visualizacao do cadastro
	oView := FWFormView():New()
	oView:SetModel(oModel)

    //Adiciona o campo virtual código produto
    oViewTMP1:AddField("TMP1_DESC", "01", "Produto","Produto", {},"C",PesqPict("SB1","B1_DESC"),Nil,/*cF3*/,.T.,Nil,Nil,Nil,Nil,Nil,.T.)
    
    //Adiciona campos virtuais grid
    oViewTMP2:AddField("TMP2_COD"    , "01", "Cod. Produto" ,"Cod. Produto"  , {},"C",PesqPict("SB1","B1_COD")      ,Nil,/*cF3*/,.F.,Nil,Nil,Nil,Nil,Nil,.T.)
    oViewTMP2:AddField("TMP2_DESC"   , "02", "Desc. Produto","Desc. Produto" , {},"C",PesqPict("SB1","B1_DESC")     ,Nil,/*cF3*/,.F.,Nil,Nil,Nil,Nil,Nil,.T.)
    oViewTMP2:AddField("TMP2_LOCAL"  , "03", "Armazem Pad." ,"Armazem Pad."  , {},"C",PesqPict("SB1","B1_LOCPAD")   ,Nil,/*cF3*/,.F.,Nil,Nil,Nil,Nil,Nil,.T.)

    //Remove os campos da grid POA
    //Deixa os campos somente pertecente a 
    //Filial de POA
    oStrGrid1:RemoveField( "Z4_CODIGO"  )
    oStrGrid1:RemoveField( "Z4_SUAPOA"  )

    //Remove os campos da grid Cachoerinha
    //Deixa os campos somente pertecente a 
    //Filial de cachoerinha
    oStrGrid2:RemoveField( "Z5_CODIGO"  )    
    oStrGrid2:RemoveField( "Z5_PRODUTO" )    
    oStrGrid2:RemoveField( "Z5_SUACHAC" ) 

    //Remove os campos da grid Itajaí
    //Deixa os campos somente pertecente a 
    //Filial de Itajaí
    oStrGrid3:RemoveField( "Z6_CODIGO"  )    
    oStrGrid3:RemoveField( "Z6_PRODUTO" )    
    oStrGrid3:RemoveField( "Z6_SUAITAJ" ) 

	oView:AddField("VIEW_SZ3CAB"    , oStrCab       , "SZ3MASTER")
	oView:AddField("VIEW_TMPCABE"   , oViewTMP1     , "TMPCABEC" )
	oView:AddGrid( "VIEW_TMPGRID"   , oViewTMP2     , "TMPGRID1" )
    oView:AddGrid( "VIEW_SZ3GRID1"  , oStrGrid1     , "SZ4GRID1" )
    oView:AddGrid( "VIEW_SZ3GRID2"  , oStrGrid2     , "SZ5GRID1" )
    oView:AddGrid( "VIEW_SZ3GRID3"  , oStrGrid3     , "SZ6GRID1" )

    //Atribui ação no Duplo Clique na GRID VIEW_TMPGRID
    oView:SetViewProperty("VIEW_TMPGRID", "GRIDDOUBLECLICK", {{|| DEFPRODUTO() }})

    //Cria as Box's na Horizontal - Somando 100%
    oView:CreateHorizontalBox( "SZ3CABEC" , 55   )
	oView:CreateHorizontalBox( "SZ3GRIDS" , 45   )

    //Cria as Box's na Vertical - Somando 100%
    //Relaciona as Box's Vertical com os Box's Horizontal
    oView:CreateVerticalBox("VCABECALH", 40 ,"SZ3CABEC")
    oView:CreateVerticalBox("VPESQCABE", 58 ,"SZ3CABEC")

    oView:CreateHorizontalBox( "PESQCABE", 30,"VPESQCABE" )
    oView:CreateHorizontalBox( "PESQGRID", 68,"VPESQCABE" )

	oView:CreateVerticalBox("VGRIDSZ31", 34  ,"SZ3GRIDS")
	oView:CreateVerticalBox("VGRIDSZ32", 33  ,"SZ3GRIDS")
	oView:CreateVerticalBox("VGRIDSZ33", 33  ,"SZ3GRIDS")

    //Relaciona as Box's Vertical com as Views
    oView:SetOwnerView( "VIEW_SZ3CAB"   , "VCABECALH" )
    oView:SetOwnerView( "VIEW_TMPCABE"  , "PESQCABE" )
    oView:SetOwnerView( "VIEW_TMPGRID"  , "PESQGRID" )
    oView:SetOwnerView( "VIEW_SZ3GRID1" , "VGRIDSZ31" )
    oView:SetOwnerView( "VIEW_SZ3GRID2" , "VGRIDSZ32" )
    oView:SetOwnerView( "VIEW_SZ3GRID3" , "VGRIDSZ33" )
    
    //Titulos de cada view que irá apresentar na tela
    oView:EnableTitleView( "VIEW_SZ3CAB"  , "Dados Orçamento" )
    oView:EnableTitleView( "VIEW_TMPCABE" , "Pesquisa Produto")
    oView:EnableTitleView( "VIEW_TMPGRID" , "Retorno Pesquisa - Clicar 2 X para incluir na Grid")
    oView:EnableTitleView( "VIEW_SZ3GRID1", "POA"             )
    oView:EnableTitleView( "VIEW_SZ3GRID2", "Cachoeirinha"    )
    oView:EnableTitleView( "VIEW_SZ3GRID3", "Itajaí"          )

Return oView 

/*/{Protheus.doc} RETPRODUT
    Retorna produto pesquisa 
    @type  Static Function
    @author Willian Kaneta
    @since 06/12/2021
    @version 1.0
/*/
Static Function RETPRODUT()
    Local cRet		:= ""
    Local nCount	:= 1
	Local oModel 	:= FWModelActive()
	Local oView     := FwViewActive()
    Local oCampoB1	:= oModel:GetModel( "TMPCABEC" )
    Local oGridPesq	:= oModel:GetModel( "TMPGRID1" )
	Local cDescProd	:= "%'%"+Alltrim(oCampoB1:GetValue( "TMP1_DESC" ))+"%'%"
    Local cAliasSB1 := GetNextAlias()
    
    BeginSql Alias cAliasSB1
        SELECT *
        FROM %TABLE:SB1% SB1
        WHERE SB1.D_E_L_E_T_    != '*'			
            AND SB1.B1_DESC LIKE %Exp:cDescProd%
        
        ORDER BY SB1.B1_DESC
    EndSql

    If !(cAliasSB1)->(EOF())
        oGridPesq:ClearData()
        While !(cAliasSB1)->(EOF())
            oGridPesq:SetLine(nCount)
            oGridPesq:SetValue("TMP2_COD"   , (cAliasSB1)->B1_COD  )
            oGridPesq:SetValue("TMP2_DESC"  , (cAliasSB1)->B1_DESC )
            oGridPesq:SetValue("TMP2_LOCAL" , (cAliasSB1)->B1_LOCPAD)

            nCount += 1
            
            (cAliasSB1)->(DbSkip())

            If (cAliasSB1)->(!EOF())	
                oGridPesq:AddLine()
            EndIf	
        EndDo

        oGridPesq:GoLine(1)
        oView:Refresh("VIEW_TMPGRID")
    Else
        MsgAlert("Nenhum produto encontrado!!")
    EndIf

    (cAliasSB1)->(DbCloseArea())
Return cRet

/*/{Protheus.doc} DEFPRODUTO
    Preenche as grids VIEW_SZ3GRID1, VIEW_SZ3GRID2 e VIEW_SZ3GRID3 após o duplo click
    na grid de pesquisa produto
    @type  Static Function
    @author Willian Kaneta
    @since 03/12/2021
    @version 1.0
/*/
Static Function DEFPRODUTO() 
    Local oModel 	:= FWModelActive()
	Local oView     := FwViewActive()
    Local oGRIDSZ31	:= oModel:GetModel( "SZ4GRID1" )
    Local oGRIDSZ32	:= oModel:GetModel( "SZ5GRID1" )
    Local oGRIDSZ33	:= oModel:GetModel( "SZ6GRID1" )
    Local oGridPesq	:= oModel:GetModel( "TMPGRID1" )
    Local cProdSZ3  := oGRIDSZ31:GetValue( "Z4_PRODUTO" )
    Local cCodProdut:= oGridPesq:GetValue( "TMP2_COD" )
    Local cLocalPad := oGridPesq:GetValue( "TMP2_LOCAL" )
    Local nSaldo01  := 0
    Local nSaldo04  := 0
    Local nSaldo05  := 0
    Local nVlrPrd01 := 0
    Local nVlrPrd04 := 0
    Local nVlrPrd05 := 0
    Local cLoc01    := GetMV("ES_LOCPOA")   
    Local cLoc04    := GetMV("ES_LOCCAC")
    Local cLoc05    := GetMV("ES_LOCITA") 
        
    If !Empty(cCodProdut) 
        If !Empty(cProdSZ3)
            oGRIDSZ31:AddLine()
            oGRIDSZ32:AddLine()
            oGRIDSZ33:AddLine()
            oGRIDSZ31:SetLine(oGRIDSZ31:Length())
            oGRIDSZ32:SetLine(oGRIDSZ32:Length())
            oGRIDSZ33:SetLine(oGRIDSZ33:Length())
        EndIf
        
        oGRIDSZ31:SetValue("Z4_PRODUTO" , cCodProdut  )

        //Filial POA    
        DbSelectArea("SB2") 
        If SB2->(MsSeek("0101" + cCodProdut + cLoc01))
            nSaldo01    := SaldoSb2()
            nVlrPrd01   := SB2->B2_CM1
        Else
            nSaldo01    := 0
            nVlrPrd01   := 0 
        EndIf   
        
        //Filial Cachoerinha      
        DbSelectArea("SB2")
        If SB2->(MsSeek("0104" + cCodProdut + cLoc04))
            nSaldo04    := SaldoSb2()
            nVlrPrd04   := SB2->B2_CM1
        Else
            nSaldo04    := 0
            nVlrPrd04   := 0 
        EndIf        
        oGRIDSZ32:SetValue("Z5_PRODUTO" , cCodProdut  )

        //Filial Itajai
        DbSelectArea("SB2")
        If SB2->(MsSeek("0105" + cCodProdut + cLoc05))
            nSaldo05    := SaldoSb2()
            nVlrPrd05   := SB2->B2_CM1
        Else
            nSaldo05    := 0
            nVlrPrd05   := 0 
        EndIf
        oGRIDSZ33:SetValue("Z6_PRODUTO" , cCodProdut  )

        oGRIDSZ31:SetValue("Z4_SLDPOA"   , nSaldo01  )
        oGRIDSZ31:SetValue("Z4_VLRPOA"   , nVlrPrd01 )         
 
        oGRIDSZ32:SetValue("Z5_SLDCHAC"  , nSaldo04  )
        oGRIDSZ32:SetValue("Z5_VLRCHAC"  , nVlrPrd04 )

        oGRIDSZ33:SetValue("Z6_SLDITAJ"  , nSaldo05  )
        oGRIDSZ33:SetValue("Z6_VLRITAJ"  , nVlrPrd05 )

        oGRIDSZ31:GoLine(1) 
        oGRIDSZ32:GoLine(1)
        oGRIDSZ33:GoLine(1)
        oView:Refresh("SZ4GRID1")
        oView:Refresh("SZ5GRID1")
        oView:Refresh("SZ6GRID1") 
    EndIf

Return .T.   
