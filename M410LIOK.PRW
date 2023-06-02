
/*/{Protheus.doc} M410LIOK
//TODO 
@description PE para Validar confirmação da operação Pedido de venda
@author Willian Kaneta
@since 25/04/2017
@version 1.0

@type function
/*/
User Function M410LIOK()
    Local lRet  := .T.				// Conteudo de retorno
	Local _aArea := GetArea()

    //Rotina para validar controle de Verbas
	If ExistBlock("UNIA031")
		lRet := ExecBlock("UNIA031", .F., .F.)
	EndIf
	
	RestArea(_aArea)
RETURN lRet
