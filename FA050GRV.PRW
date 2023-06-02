#include 'totvs.ch'

/*/{Protheus.doc} User Function FA050GRV
    Ponto de entrada para tratar dados após o titulo SE2 estar gravado
    @type  Function
    @author Willian Kaneta
    @since 22/11/2021
    @version 1.0
    /*/
User Function FA050GRV()
    Local _aArea    := GetArea()
    Local _aAreaSE2 := SE2->(GetArea())

    //Rotina para validar controle de Verbas
	If ExistBlock("UNIA032")
		ExecBlock("UNIA032", .F., .F.)
	EndIf

    RestArea(_aAreaSE2)
    RestArea(_aArea)
Return Nil
