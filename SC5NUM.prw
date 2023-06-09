#include "protheus.ch"
#include "rwmake.ch"

/*/{Protheus.doc} INICA1Cod
    Função inicializador padrão do campo a1_cod
@author Caio.Lima
@since 22/07/2022
/*/
User Function SC5NUM()
    Local _cSql as character
    Local _cCod as character
    _cSql := ""

    _cSql += " SELECT MAX(C5_NUM) MAXCOD FROM "+RetSQLName('SC5')+" SC5 "+CRLF
    _cSql += " WHERE SC5.D_E_L_E_T_<>'*' "+CRLF
    _cSql += " AND C5_FILIAL = '"+xfilial("SC5")+"' "+CRLF

    _cCod := MPSysExecScalar( _cSql, "MAXCOD")
    If Empty(_cCod)
        _cCod := "000001"
    Else
        _cCod := Soma1(_cCod)
    EndIf
    While !MayIUseCod(_cCod+"SC5"+cFilAnt)
        _cCod := Soma1(_cCod)
    End
Return(_cCod)
