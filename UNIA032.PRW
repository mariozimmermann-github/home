#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} UNIA032
//TODO 
@description Validação inclusão PV X Verbas
@author Willian Kaneta
@since 25/04/2017
@version 1.0

@type function
/*/
user function UNIA032()
	Local aAreaSC6 	:= SC6->(GetArea())

	If FWIsInCallStack('U_M410STTS')
		DbSelectArea('SC6')
		dbSetOrder(1)
		
		If MsSeek((xfilial("SC6")+SC5->C5_NUM))
			While SC6->(!Eof()) .AND. SC6->(C6_FILIAL+C6_NUM) == SC5->(C5_FILIAL+C5_NUM)
				DbSelectArea("SZ2")
				SZ2->(DbSetorder(1))

				If MsSeek(xFilial("SZ2")+SC6->C6_CODVERB+PADR(SC5->C5_CLIENTE,TAMSX3("Z2_CLIENTE")[1])+SC5->C5_LOJACLI)
					If RecLock('SZ2',.F.)
						SZ2->Z2_VALOR := SZ2->Z2_VALOR - SC6->C6_VALOR
						SZ2->(MsUnlock())
					EndIf
				EndIf
				SC6->(DbSkip())
			Enddo
		EndIf
	ElseIf FWIsInCallStack('U_FA050GRV')

		DbSelectArea("SA2")
		SA2->(DbSetOrder(1))

		If SA2->(MsSeek(xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA))
			DbSelectArea("SA1")
			SA1->(DbSetOrder(3))

			If SA1->(MsSeek(xFilial("SA1")+SA2->A2_CGC))
				DbSelectArea("SZ2")
				SZ2->(DbSetorder(1))

				If MsSeek(xFilial("SZ2")+SE2->E2_CODVERB+PADR(SA1->A1_COD,TAMSX3("Z2_CLIENTE")[1])+SA1->A1_LOJA)
					If RecLock('SZ2',.F.)
						SZ2->Z2_VALOR := SZ2->Z2_VALOR - SE2->E2_VALOR
						SZ2->(MsUnlock())
					EndIf	
				EndIf
			EndIf
		EndIf

	EndIf

	RestArea(aAreaSC6)
Return Nil
