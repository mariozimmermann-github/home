#Include "Totvs.ch"
#Include "FWMVCDef.ch"

/*/{Protheus.doc} User Function UNIA037
    Função para realizar a importação Pedidos de vendas API VNDA.
    @type  Function
    @author Willian Kaneta
    @since 06/12/2021
    @version 1.0
    /*/
User Function UNIA037()
    Private oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("SZ7")
	oBrowse:SetDescription("Pedidos VNDA")
	oBrowse:DisableDetails()
	oBrowse:Activate()

Return

/*/{Protheus.doc} MenuDef
//TODO
@decription Menu
@author Willian Kaneta
@since 08/03/2017
@version 1.0

@type function
/*/
Static Function MenuDef()

	Local aRotina := {}
	
	ADD OPTION aRotina TITLE "Pesquisar"  	ACTION "PesqBrw" 		   OPERATION 1 ACCESS 0
	ADD OPTION aRotina TITLE "Visualizar" 	ACTION "VIEWDEF.FSCO02WK"  OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE "Incluir"   	ACTION "VIEWDEF.FSCO02WK"  OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE "Alterar"    	ACTION "VIEWDEF.FSCO02WK"  OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Excluir"    	ACTION "VIEWDEF.FSCO02WK"  OPERATION 5 ACCESS 0

Return aRotina

/*/{Protheus.doc} ModelDef
//TODO
@decription Camada de modelo de dados
@author Willian Kaneta
@since 08/03/2017
@version 1.0

@type function
/*/
Static Function ModelDef()
	Local oModel
	Local oStr1		:= FWFormStruct( 1,'SZ7')
	Local oStr2		:= FWFormStruct( 1,'SZ8')

	Private cDoc 	:= ""

	oModel := MPFormModel():New('UNIA037M', /*bPreValidacao*/, { | oModel | MVC001V( oModel ) } , /*{ | oMdl | MVC001C( oMdl ) }*/ ,, /*bCancel*/ )

	oModel:SetDescription('Editar Pedidos de vendas VNDA')
	oModel:AddFields( "SZ7MASTER", Nil, oStr1 )

	oModel:SetPrimaryKey( { 'Z7_FILIAL','Z7_CODIGO','Z7_CLIENTE','Z7_LOJA' } )

	oModel:AddGrid('SZ8GRID1','SZ7MASTER',oStr2)
	oModel:SetRelation( "SZ8GRID1", { { "Z8_FILIAL", "xFilial( 'SZ8' )" }, { "Z8_CODPEDI", "Z7_CODIGO" } }, SZ8->( IndexKey( 1 ) ) )
	oModel:getModel('SZ7MASTER'):SetDescription('Integração API Pedidos de vendas VNDA')
	
Return oModel

/*/{Protheus.doc} ViewDef
//TODO
@decription Camada de visualização
@author Willian Kaneta
@since 08/03/2017
@version 1.0

@type function
/*/
Static Function ViewDef()
	Local oModel 		:= ModelDef()
	Local oView  		:= FWFormView():New()
	Local oStruSZ71  	:= FWFormStruct(2, 'SZ7')
	Local oStruSZ81  	:= FWFormStruct(2, 'SZ8')

	oView:SetModel( oModel )
	oView:AddField( "VIEW_SZ71", oStruSZ71 , "SZ7MASTER" )
	oView:AddGrid(  "VIEW_SZ81", oStruSZ81 , "SZ8GRID1" )
		
	oView:AddIncrementField( 'VIEW_SZ81', 'ZZ7_ITEM' )

	oView:CreateHorizontalBox( "CAMPOS" , 30   )
	oView:CreateHorizontalBox( "GRID1"  , 70   )

	oView:CreateVerticalBox("VCABECAL", 100 ,"CAMPOS" 	)
	oView:CreateVerticalBox("VGRIDSZ8", 100 ,"GRID1" 	)

	oView:SetOwnerView( "VIEW_SZ71", "VCABECAL" )
	oView:SetOwnerView( "VIEW_SZ81", "VGRIDSZ8" )

	oView:EnableTitleView( "VIEW_SZ71"           )
	oView:EnableTitleView( "VIEW_SZ81"           )

Return oView

/*/{Protheus.doc} MVC001V
//TODO
@description Validação Dados ao incluir/alterar
@author Willian Kaneta
@since 08/03/2017
@version 1.0
@param oModel, object, descricao
@type function
/*/
Static Function MVC001V( oModel )
	Local lRet      	:= .T.

Return lRet

