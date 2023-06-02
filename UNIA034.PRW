#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} UNIA034
//TODO 
@description Grava campo na inclusão Doc X NCC BNA
@author Willian Kaneta
@since 25/04/2017
@version 1.0

@type function
/*/
user function UNIA034()
	Local lRet 		:= .T.
	Local aArea 	:= GetArea()
	Local aAreaSE1 	:= SE1->(GetArea())
		
	If !Empty(SC5->C5_TITNCC)
		DbSelectArea("SE1")
		SE1->(DbSetOrder(1))

		If SE1->(MsSeek(SC5->C5_TITNCC))
			If RecLock('SE1',.F.)
				If !Empty(SE1->E1_NFCOMP)
					SE1->E1_NFCOMP  := Alltrim(SE1->E1_NFCOMP) + "/" + Alltrim(SF2->F2_DOC) +"-"+Alltrim(SF2->F2_SERIE)
				Else
					SE1->E1_NFCOMP	:= Alltrim(SF2->F2_DOC) +"-"+Alltrim(SF2->F2_SERIE)
				EndIf
				SE1->(MsUnlock())
			EndIf
		EndIf
			
	EndIf

	RestArea(aAreaSE1)
	RestArea(aArea)
Return lRet
