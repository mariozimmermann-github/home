#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} UNIA030
//TODO 
@description Rotina Comiss�o de frota
@author Willian Kaneta
@since 25/04/2017
@version 1.0

@type function
/*/
user function UNIA030()
	Private oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("SZ2")
	oBrowse:SetDescription("Cadastro de Verbas ")
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
	
	ADD OPTION aRotina TITLE "Pesquisar"  	ACTION 'PesqBrw' 		  OPERATION 1 ACCESS 0
	ADD OPTION aRotina TITLE "Visualizar" 	ACTION "VIEWDEF.UNIA030"  OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE "Incluir"   	ACTION "VIEWDEF.UNIA030"  OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE "Alterar"    	ACTION "VIEWDEF.UNIA030"  OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Excluir"    	ACTION "VIEWDEF.UNIA030"  OPERATION 5 ACCESS 0

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
	Local oStr1		:= FWFormStruct( 1,'SZ2')

	Private cDoc 	:= ""

	oModel := MPFormModel():New('Cadastro de Verbas ', , { | oModel | MVC001V( oModel ) } , /*{ | oMdl | MVC001C( oMdl ) }*/ ,, /*bCancel*/ )

	oModel:SetDescription(' Editar Cadastro de Verbas ')
	oModel:AddFields( "SZ21UNICO", Nil, oStr1 ) 
							
	oModel:SetPrimaryKey( { 'Z2_FILIAL', 'Z2_CODIGO' } )
	
	oModel:getModel('SZ21UNICO'):SetDescription('Cadastro de Verbas Uniagro')

	oStr1:SetProperty("Z2_APROV", MODEL_FIELD_WHEN, {|| A080APROV() } )	

Return oModel

/*/{Protheus.doc} ViewDef
//TODO
@decription Camada de visualiza��o
@author Willian Kaneta
@since 08/03/2017
@version 1.0

@type function
/*/
Static Function ViewDef()

	Local oModel 		:= ModelDef()
	Local oView  		:= FWFormView():New()
	Local oStruSZ21  	:= FWFormStruct(2, 'SZ2')
	
	oView:SetModel( oModel )
	oView:SetContinuousForm(.T.)
	oView:AddField( "VIEW_SZ21", oStruSZ21 , "SZ21UNICO" )

	oView:CreateHorizontalBox( "CAMPOS" , 100   )

	oView:SetOwnerView( "VIEW_SZ21", "CAMPOS" )

	oView:EnableTitleView( "VIEW_SZ21" )

Return oView

/*/{Protheus.doc} MVC001V
//TODO
@description Valida��o Dados ao incluir/alterar
@author Willian Kaneta
@since 08/03/2017
@version 1.0
@param oModel, object, descricao
@type function
/*/
Static Function MVC001V( oModel )

	Local lRet      := .T.

	FwModelActive( oModel, .T. )

Return lRet


/*/{Protheus.doc} A080APROV
//TODO
Validação se usuário pode aprovar verba
@author Daniel Barcelos
@since 17/08/2022
@version 1.0
@param oModel, object, descricao
@type function
/*/
Static Function A080APROV( oModel )

	Local lRet      := .F.
	
	dbSelectArea("ZAC")
	dbSetOrder(1)
	If ZAC->( dbSeek( SZ2->Z2_FILIAL + __cUserID ) )

		If ZAC->ZAC_VALOR >= SZ2->Z2_VALOR
			lRet:= .T.
		EndIf

	EndIf

Return lRet
