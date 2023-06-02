#include 'totvs.ch'

/*/{Protheus.doc} User Function FA050ALT
    O ponto de entrada FA050ALT será executado na validação da Tudo Ok na alteração dos dados do contas a pagar.
    @type  Function
    @author Willian Kaneta
    @since 22/11/2021
    @version 1.0
    /*/
User Function FA050ALT()
    Local lRet  := .T.				// Conteudo de retorno
	Local _aArea := GetArea()
    Local _aAreaSE2 := SE2->(GetArea())

    //Rotina para validar controle de Verbas
	If ExistBlock("UNIA033")
		lRet := ExecBlock("UNIA033", .F., .F.)
	EndIf
	
    RestArea(_aAreaSE2)
	RestArea(_aArea)
RETURN lRet
