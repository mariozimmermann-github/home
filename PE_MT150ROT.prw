#Include "Totvs.ch"

/*/{Protheus.doc} MT150ROT
    Função da atualização de cotações. EM QUE PONTO : No inico da rotina e antes da execução da Mbrowse da cotação, utilizado para adicionar mais opções no aRotina.
    @type  Function
    @author Denis Rodrigues
    @since 19/04/2022
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example (examples)
    @see https://tdn.totvs.com/pages/releaseview.action?pageId=6085637
/*/
User Function MT150ROT()

    aAdd ( aRotina, { 'Mensagem Forn.',"U_TRSF150(SC8->C8_NUM,SC8->C8_FORNECE,SC8->C8_LOJA)", 0, 4 } )
    
Return( aRotina )
