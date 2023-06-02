//Bibliotecas
#Include "Totvs.ch"
#Include "FWMVCDef.ch"

/*/{Protheus.doc} User Function UNIA010
Consulta Saldos por filial
@author Daniel Barcelos
@since 26/11/2021
@version 1.0
@type function
/*/
 
User Function UNIC010(nCodigo)   
	Local aArea     := GetArea()
	Local nOp       := 3
    Local aButtons  := {{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.T.,"Fechar"},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil}}

    Default nCodigo := ""

        //Executa a tela Saldos Produtos
    nRet := FWExecView('Saldos Produtos X Televendas','UNIC011', nOp,,{||.T.},,,aButtons,,,,)
    
	RestArea(aArea) 

Return Nil       

