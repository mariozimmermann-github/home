#Include "Totvs.ch"

/*/{Protheus.doc} User Function MT161OK
    O ponto de entrada MT161OK é usado para validar as propostas dos fornecedores no 
    momento da gravação da análise da cotação, após o fechamento da tela. 
    Se .T. finaliza o processo. Se .F., interrompe o processo.    
    @type  Function
    @author Denis Rodrigues
    @since 25/04/2022
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example (examples)
    @see https://tdn.totvs.com/display/public/PROT/MT161OK+-+Ponto+utilizado+para+validar+as+propostas+dos+fornecedores
/*/
User Function MT161OK()

    Local aArea   := GetArea()
    Local aPropPE := PARAMIXB[1]

    U_TRSF140(aPropPE,SC8->C8_NUM) //Usado para enviar e-mail para informar ao Fornecedor que ele foi selecionado.

    RestArea( aArea )
    
Return(.T.)
