#include "totvs.ch"

/*/{Protheus.doc} User Function MS520DEL
    Esse ponto de entrada est� localizado na fun��o MaDelNfs e � executado antes da exclus�o do registro da tabela SF2.
    @type  Function
    @author Daniel Barcelos
    @since 11/03/2022 
    @see https://tdn.totvs.com/display/public/PROT/MS520DEL
/*/
User Function MS520DEL()

    Local aArea   := GetArea() 
    Local cNumDoc := SF2->F2_DOC    
    Local cNumSer := SF2->F2_SERIE
    Local cFili := SF2->F2_FILIAL 
    Local cAliasT := ' '
    Local cQuery:= ""
    
    If cFili $ '0104/0105'

        cAliasT := GetNextAlias()
        cQuery:= " SELECT SC9.c9_filial,"
        cQuery+= "        SC9.c9_pedido," 
        cQuery+= "        SC9.c9_item, "
        cQuery+= "        SC9.c9_LOTECTL,"
        cQuery+= "        SC9.c9_qtdrese,"
        cQuery+= "        SC9.c9_DTVALID,"
        cQuery+= "        SC9.c9_STSERV,"
        cQuery+= "        SC9.c9_SEQUEN,"
        cQuery+= "        SC9.C9_NFISCAL, " 
        cQuery+= "        SC9.r_e_c_n_o_ "
        cQuery+= "      FROM    " + RetSqlName("SC9") + "  SC9 "
        cQuery+= " INNER JOIN (SELECT TSC9.c9_filial, " 
        cQuery+= "     TSC9.c9_pedido, "
        cQuery+= "             TSC9.c9_item, "
        cQuery+= "                 Max(TSC9.r_e_c_n_o_) REC "
        cQuery+= "          FROM    " + RetSqlName("SC9") + "  TSC9 "
        cQuery+= "          WHERE  TSC9.c9_filial = '" + cFili + "' "
        cQuery+= "                 AND TSC9.c9_NFISCAL = '" + cNumDoc + "' "
        cQuery+= "                 AND TSC9.c9_SERIENF = '" + cNumSer + "' "
        cQuery+= "                 AND TSC9.d_e_l_e_t_ = '*' "
        cQuery+= "          GROUP  BY TSC9.c9_filial, "
        cQuery+= "                    TSC9.c9_pedido, "
        cQuery+= "                    TSC9.c9_item) TSC9 "
        cQuery+= "      ON TSC9.rec = SC9.r_e_c_n_o_ "
        cQuery+= " WHERE  SC9.c9_filial = '" + cFili + "'   "

        cQuery := ChangeQuery( cQuery ) 

	    dbUseArea( .T., "TOPCONN",TcGenQry( ,,cQuery ),cAliasT,.F.,.T. ) 

	    While (cAliasT)->(!Eof())  

            dbSelectArea("SC9")
            dbSetOrder(1)//C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
            If dbSeek( xFilial("SC9") + (cAliasT)->C9_PEDIDO + (cAliasT)->C9_ITEM + (cAliasT)->C9_SEQUEN )

                RecLock('SC9',.F.)
                    SC9->C9_BLEST   := " "
                    SC9->C9_LOTECTL := (cAliasT)->C9_LOTECTL
                    SC9->C9_DTVALID := StoD((cAliasT)->C9_DTVALID)
                    SC9->C9_STSERV  := (cAliasT)->C9_STSERV 
                Msunlock() 

            EndIf   

            (cAliasT)->( dbSkip() ) 

        EndDo 

        (cAliasT)->(dbCloseArea()) 
    EndIf

    // Exclui contas a receber gerado para pedidos de bonificação BNF
    dbSelectArea("SE1")
    SE1->(dbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
    If dbSeek( xFilial("SE1") + 'BNF' + cNumDoc + '01' )

        Reclock("SE1",.F.)
            SE1->( dbDelete() )
        Msunlock()

    EndIf

    RestArea(aArea)
 
Return   
 