#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} UNIA044
@description Cria contas a receber caso pedido seja de verba.
@author Daniel Barcelos
@since 19/08/2022
@version 1.0
/*/
user function UNIA044()

	Local lRet 		:= .T.
	Local aArea 	:= GetArea()
	Local aAreaSE1 	:= SE1->(GetArea())
	Local aAreaSC5 	:= SC5->(GetArea())
	Local aAreaSC6 	:= SC6->(GetArea())
	Local cTesVB    := GetMv("ES_TESVERB")
	Local cNatur    := SuperGetMV('ES_NATVERB',.F.,'201209')
	Local aSE1      := {}
	Local nTotPed   := 0
	Private lMsErroAuto:= .F.

	dbSelectArea("SC6")
	dbSetOrder(1)
	If SC6->( dbSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )

		While SC6->( !EOF() ) .And. SC6->C6_NUM = SC5->C5_NUM

			If SC6->C6_TES $ cTesVB 

				nTotPed+= SC6->C6_VALOR

			EndIf

			SC6->( dbSkip() )

		EndDo

	EndIf

	If nTotPed > 0

	aSE1 := {	{"E1_PREFIXO" ,'BNF'           ,NIL},;
				{"E1_NUM"     ,SF2->F2_DOC     ,NIL},;
				{"E1_PARCELA" ,'01'             ,NIL},;
				{"E1_TIPO"    ,'NCC'           ,NIL},;
				{"E1_NATUREZ" ,cNatur          ,NIL},;
				{"E1_CLIENTE" ,SC5->C5_CLIENTE ,NIL},;
				{"E1_LOJA"    ,SC5->C5_LOJACLI ,NIL},;
				{"E1_VENCTO"  ,SF2->F2_EMISSAO ,NIL},;
				{"E1_EMISSAO" ,SF2->F2_EMISSAO ,NIL},;
				{"E1_VALOR"   ,nTotPed         ,NIL},;
				{"E1_PEDIDO"  ,SC5->C5_NUM     ,NIL}}

				//	{"E1_TIPO"    ,'NCC'           ,NIL},;
			//		{"E1_NATUREZ" ,"101001    " ,NIL},;
		//			{"E1_CLIENTE" ,SC5->C5_CLIENTE ,NIL},;
	//				{"E1_LOJA"    ,SC5->C5_LOJACLI ,NIL},;
	//				{"E1_VENCTO"  ,SF2->F2_EMISSAO  ,NIL},;

		MsExecAuto({|x,y| FINA040(x,y)}, aSE1, 3)  // 3 - Inclusao, 4 - Altera��o, 5 - Exclus�o
				
		If lMsErroAuto
			_lRet := .F.
			MostraErro()
		Else
			_lRet := .T.
		EndIf	

	EndIf


	RestArea(aAreaSE1)
	RestArea(aAreaSC5)
	RestArea(aAreaSC6)
	RestArea(aArea)
Return lRet
