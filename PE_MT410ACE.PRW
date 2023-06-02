#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
/*
+-----------+-----------+-------+------------------------------------------------------+------+----------+
| Funcao    | MT410ACE  | Autor | Manoel M Mariante                                    | Data |fev/2022  |
|-----------+-----------+-------+------------------------------------------------------+------+----------|
| Descricao | PE na rotina de Pedidos de Venda para nn�o permitir a altera��o de pedidos                 |
|           | ja integrados com  WMS                                                                     |
|           |                                                                                            |
|-----------+--------------------------------------------------------------------------------------------|
| Sintaxe   | ponto de entrada na MATA410                                                                |
+-----------+--------------------------------------------------------------------------------------------+
*/
User Function MT410ACE()
	Local lRet:=.t.,nTotal:=0
    Local cQuery:=''
    Local aArea:=GetArea()

    IF ALTERA .and. xFilial('SC5')$SuperGetMV('ES_FILWMS',.f.,'0104/0105')
        
        cQuery:=' SELECT SUM(C6_LIBWMS+C6_EMPWMS) TOTAL '
        cQuery+=' FROM '+RetSqlTab('SC6')
        cQuery+=' WHERE '+RetSqlfil('SC6')
        cQuery+=' AND '+RetSqldEL('SC6')
        cQuery+=" AND C6_NUM='"+SC5->C5_NUM+"'"
        
        cQuery := ChangeQuery( cQuery )
	    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),'TRBX',.F.,.T.)    

        nTotal:=TRBX->TOTAL

        DBCLOSEAREA()
        
        If nTotal>0
		    MsgInfo('Altera��o N�o Permitida Quando Integra��o com WMS j� foi Iniciada','Integra��o com WMS')
       		lRet:=.f.
        EndIf

        cQuery:=' SELECT SC9.C9_PEDIDO '
        cQuery+=' FROM '+RetSqlTab('SC9')
        cQuery+=' WHERE '+RetSqlfil('SC9')
        cQuery+=" AND C9_PEDIDO ='"+SC5->C5_NUM+"'"
        
        cQuery := ChangeQuery( cQuery )
	    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),'TRBX',.F.,.T.)    
        
        If TRBX->( !EOF() )
            MsgInfo('Altera��o N�o Permitida Quando Integra��o com WMS j� foi Iniciada','Integra��o com WMS')
       		lRet:=.f.
        EndIf

        DBCLOSEAREA()

        REstArea(aArea)

	EndIf

        

Return lRet
