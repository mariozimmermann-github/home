#include 'totvs.ch'

/*/{Protheus.doc} User Function M410STTS
    Ponto de entrada executado após todas as alterações no arquivo de pedidos terem sido feitas.
    @type  Function
    @author Willian Kaneta
    @since 19/11/2021
    @version 1.0
    /*/
User Function M410STTS()
    Local _aArea  	 	:= GetArea()
    Local nOpc     := PARAMIXB[1] 
    
     //Rotina para validar controle de Verbas
	If ExistBlock("UNIA032")
		ExecBlock("UNIA032", .F., .F.)
	EndIf

    If nOpc = 6 // Copia 
    
        dbSelectArea("SC6")
        dbSetOrder(1)
        If dbSeek( xFilial("SC6") + SC5->C5_NUM )

            While SC6->( !EoF() ) .And. SC6->C6_NUM = SC5->C5_NUM

                RecLock("SC6", .F.)
                    SC6->C6_LIBWMS:= 0
                    SC6->C6_EMPWMS:= 0
                MsUnlock()

                SC6->( dbSkip() ) 

            EndDo
        EndIf

    EndIf

    RestArea(_aArea) 

Return Nil
