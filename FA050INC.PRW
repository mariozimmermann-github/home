#include 'totvs.ch'

/*/{Protheus.doc} User Function FA050INC
    O ponto de entrada FA050INC será executado na validação da Tudo Ok na inclusão dos dados do contas a pagar.
    @type  Function
    @author Willian Kaneta
    @since 22/11/2021
    @version 1.0
    /*/
User Function FA050INC()
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
