#include 'protheus.ch'

/*/{Protheus.doc} UNIA031
//TODO 
@description Valida��o inclus�o PV X Verbas
@author Willian Kaneta
@since 25/04/2017
@version 1.0

@type function
/*/
user function UNIA031()
	Local lRet 			:= .T.
	Local nX 			:= 0
	Local nVltTotVer	:= 0
	Local nPosVlrTot  	:= Ascan(Aheader,{|x| AllTrim(x[2]) == "C6_VALOR" })
	Local nPosVerbas  	:= Ascan(Aheader,{|x| AllTrim(x[2]) == "C6_CODVERB" })
	Local nPosTESC6  	:= Ascan(Aheader,{|x| AllTrim(x[2]) == "C6_TES" })
	Local _cTesBNF		:= SuperGetMV("ES_TESVERB",.F.,"")

	If !Empty(acols[n][nPosVerbas]) .AND. Alltrim(acols[n][nPosTESC6]) $ _cTesBNF
		
		DbSelectArea("SZ2")
		SZ2->(DbSetorder(1))

		If MsSeek(xFilial("SZ2")+acols[n][nPosVerbas]+PADR(M->C5_CLIENTE,TAMSX3("Z2_CLIENTE")[1])+M->C5_LOJACLI)
			If SZ2->Z2_APROV == "1"
				For nX := 1 To Len(acols)
					If acols[nX][nPosVerbas] == SZ2->Z2_CODIGO
						nVltTotVer += acols[nX][nPosVlrTot]
					EndIf
				Next nX 
				If M->C5_EMISSAO > SZ2->Z2_VIGFIM .OR. M->C5_EMISSAO < SZ2->Z2_VIGINI
					Help(NIL, NIL, "HELP", NIL, "Data de emissao fora da vigencia do cadastro de verbas!", 1,0, NIL, NIL, NIL, NIL, NIL,;
						{"Verificar se a verba informada esta vigente."})
					lRet := .F.
				Else
					If nVltTotVer > SZ2->Z2_VALOR
						Help(NIL, NIL, "HELP", NIL, "Valor Acima do Saldo da Verba!", 1,0, NIL, NIL, NIL, NIL, NIL,;
						{"Verificar o valor da verba X valor do item informado"})
						lRet := .F.
					EndIf
				EndIf
			Else
				Help(NIL, NIL, "HELP", NIL, "Verba nao Aprovada para o cliente: "+M->C5_CLIENTE+"Loja: "+M->C5_LOJACLI, 1,0, NIL, NIL, NIL, NIL, NIL,;
					{"E necessário aprovar a Verba no cadastro de Verbas para poder utilizar!"})
				lRet := .F.
			EndIf
		Else
			Help(NIL, NIL, "HELP", NIL, "Cliente nao cadastrado no cadastro de Verbas!", 1,0, NIL, NIL, NIL, NIL, NIL,;
				{"Verificar se o cliente esta cadastrado no cadastro de verbas ou selecionar a verba correta para o cliente."})
			lRet := .F.
		EndIf
	ElseIf Empty(acols[n][nPosVerbas]) .AND. Alltrim(acols[n][nPosTESC6]) $ _cTesBNF
		Help(NIL, NIL, "HELP", NIL, "Codigo de verba nao informado!", 1,0, NIL, NIL, NIL, NIL, NIL,;
					{"Informar o codigo da verba!"})
		lRet := .F.
	ElseIf !Empty(acols[n][nPosVerbas]) .AND. !Alltrim(acols[n][nPosTESC6]) $ _cTesBNF
		Help(NIL, NIL, "HELP", NIL, "Tes informada não está no parâmetro ES_TESVERB !", 1,0, NIL, NIL, NIL, NIL, NIL,;
					{"Informar o codigo da verba!"})
		lRet := .F.		
	EndIf 
		

Return lRet
