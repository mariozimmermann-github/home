#Include "Totvs.ch"
#Include "FWMVCDef.ch"

/*/{Protheus.doc} User Function UNIA080
    Cadastro de aprovadores de verba.
    @type  Function
    @author Daniel Barcelos
    @since 17/08/2022
/*/ 
User Function UNIA080()  

	Local oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZAC") 
	oBrowse:SetDescription("Cadastro de Aprovadores de Verbas")

	oBrowse:Activate()        
	
Return    
 
/*/{Protheus.doc} MenuDef
    Fun��o para a montagem do Menu
    @type  Static Function
    @author Daniel Barcelos
    @since 17/06/2022
/*/
Static Function MenuDef() 

   Local aRotina := {} 

   ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.UNIA080'    OPERATION 2 ACCESS 0 
   ADD OPTION aRotina TITLE 'Incluir'    ACTION 'VIEWDEF.UNIA080'    OPERATION 3 ACCESS 0 
   ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.UNIA080'    OPERATION 4 ACCESS 0 
   ADD OPTION aRotina TITLE 'Excluir'    ACTION 'VIEWDEF.UNIA080'    OPERATION 5 ACCESS 0 

Return(aRotina)                
  

/*/{Protheus.doc} ModelDef
    Fun��o MVC ModelDef
    @type  Static Function
    @author Daniel Barcelos
    @since 17/06/2022
/*/ 
Static Function ModelDef()     

	Local oStruZAC := FWFormStruct( 1,"ZAC" ) 
	Local oModel 
	
	oModel := MPFormModel():New("UNIA080M",/*bVldPre*/,/*bVldPos*/,/*bVldCom*/)
	
	oModel:AddFields( "ZACMASTER", /*cOwner*/, oStruZAC)	
	oModel:SetPrimaryKey( { "ZAC_FILIAL", "ZAC_USER" } ) 
	oModel:SetDescription("Cadastro aprovação de verbas")
	oModel:GetModel("ZACMASTER"):SetDescription("Cadastro aprovação de verbas")

	oModel:SetVldActivate( { |oModel| A080VAL( oModel ) } )

Return oModel     
 
/*/{Protheus.doc} ViewDef 
    Fun��o MVC ModelDef
    @type  Static Function
    @author Daniel Barcelos
    @since 17/06/2022
/*/
Static Function ViewDef()

	Local oModel := FWLoadModel("UNIA080")
	Local oStruZAC := FWFormStruct( 2,"ZAC")
	Local oView := FWFormView():New()
	
	oView:SetModel( oModel )
	oView:Addfield( "VIEW_ZAC", oStruZAC, "ZACMASTER" )
	oView:CreateHorizontalBox( "TELA",100 )
	oView:SetOwnerView( "VIEW_ZAC", "TELA" )
	
Return( oView )      


/*/{Protheus.doc} A080VAL
	"Liberdo para admin"
	@type  Static Function
	@author Daniel Barcelos
	@since 18/08/2022
/*/
Static Function A080VAL( oModel )
	
	Local lRet:= .F.
	Local aGrp:= {}

	aGrp:= UsrRetGrp(__cUserID) 

	If aScan(aGrp,'000000') > 0
		lRet:= .T.
	Else
		Help( ,, 'HELP',, 'Usuário sem Permissão', 1, 0)      
	EndIf

Return lRet
