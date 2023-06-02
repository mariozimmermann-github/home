#include "rwmake.ch"
#include "Protheus.ch"
#include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} M460FIM

Ponto de entrada executado no final da geracao da NF Saida,
utilizado para gravacao de dados adicionais.

@author ASRConsult - Allan Constantino Bonfim
@since  17/11/2021
@version P12
@return NIL

/*/
//-------------------------------------------------------------------
User Function M460FIM()

	Local _aArea  	 	:= GetArea()
	//Local _aAreaSC9     := SC9->( GetArea() )
	Local _aParam		:= {SF2->(RECNO()), SA1->(RECNO())}
	Local cQuery    	:= GetNextAlias()		//Bruno Ribeiro Rocha - 15/02/2022
	//Local cFormPag  	:= SE4->E4_FORMA		//Bruno Ribeiro Rocha - 15/02/2022
	Local cFormPag  	:= If(SA1->A1_FORMA='S','BOL',' ')		//Daniel Barcelos     - 08/04/2022
	Local cNumTit   	:= SE1->E1_NUM			//Bruno Ribeiro Rocha - 15/02/2022
	Local cPrefTit  	:= SE1->E1_PREFIXO		//Bruno Ribeiro Rocha - 15/02/2022
	Local cTipoTit  	:= SE1->E1_TIPO			//Bruno Ribeiro Rocha - 15/02/2022
	Local cParcTit  	:= SE1->E1_PARCELA		//Bruno Ribeiro Rocha - 15/02/2022
	Local nErro     	:= 0					//Bruno Ribeiro Rocha - 15/02/2022

	//Rotina para controle de rappel 
	If ExistBlock("UNIAP001")
		ExecBlock("UNIAP001", .F., .F., _aParam) 
	EndIf

	//Controle de Verbas - Grava dados NF na NCC 
	//caso o campo C5_TITNCC estiver preenchido.
	If ExistBlock("UNIA034")
		ExecBlock("UNIA034", .F., .F.)
	EndIf

	RestArea(_aArea)   
/*
	//Grava��o da forma de pagamento nos t�tulos gerados
	//Altera��o realizada em 15/02/2022 - Bruno Ribeiro Rocha (TOTVS RS)
	IF EMPTY(cParcTit)

    	RecLock("SE1", .F.)  
        	E1_FORMA := cFormPag        
    	MsUnlock() 

	ELSE 

    	BEGIN TRANSACTION

    	cQuery := " UPDATE " + RETSQLName("SE1") + " "
    	cQuery += " SET E1_FORMA ='" + cFormPag + "' "
    	cQuery += " WHERE E1_FILIAL ='" + FWxFilial("SE1") + "' "
    	cQuery += " AND E1_NUM ='" + cNumTit + "' "
    	cQuery += " AND E1_PREFIXO = '" + cPrefTit + "' "
    	cQuery += " AND E1_TIPO ='" + cTipoTit + "' "
    	cQuery += " AND D_E_L_E_T_ = ' ' "

    	nErro := TcSqlExec(cQuery)

	    If nErro != 0
    	    MsgStop("Erro na execução da query: "+TcSqlError(), "Atenção")
        	DisarmTransaction()
    	EndIf

    	END TRANSACTION 

	ENDIF
*/
	//Controle de Verbas - Grava contas a receber
	//caso o pedido tes esteja no parametro ES_TESVERB.
	If ExistBlock("UNIA044")
		ExecBlock("UNIA044", .F., .F.)
	EndIf

Return  
