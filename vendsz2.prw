#INCLUDE "TOTVS.CH"

//--------------------------------------------------------------------------------------
/*/{Protheus.doc} VENDSZ2
@Type			: Função de Usuário
@Sample			: U_VENDSZ2()
@Description	: Rotina para mostrar nome do vendedor cadastrado ao cliente do SA1
@Param			: cCodCli ; cLojcli
@Return			: Nenhum
@ --------------|-----------------------------------------------------------------------
@Author			: Evandro Mugnol
@Since			: Jan/2023
@version		: Protheus 12.1.33 e posteriores
@Comments		: Nenhum
/*/
//--------------------------------------------------------------------------------------
User Function VENDSZ2(_cTipo,_cCliente,_cLojaCli)

    Local _aArea     := FWGetArea()
    Local _cNomeVend := ""

    DO CASE
        CASE _cTipo == "R"
            _cNomeVend := If(!INCLUI,  Posicione("SA3",1,xFilial("SA3")+Posicione("SA1",1,xFilial("SA1")+SZ2->Z2_CLIENTE+SZ2->Z2_LOJA,"A1_VEND"),"A3_NOME"),"")
        CASE _cTipo == "B"
            _cNomeVend := Posicione("SA3",1,xFilial("SA3")+Posicione("SA1",1,xFilial("SA1")+SZ2->Z2_CLIENTE+SZ2->Z2_LOJA,"A1_VEND"),"A3_NOME")
    ENDCASE

    FWRestArea(_aArea)

Return(_cNomeVend)
