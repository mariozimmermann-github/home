#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "SIGAWIN.CH"
#include "topconn.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³ 8B_PAGFOR  ³ Autor ³ Clei@8bit           ³ Data ³ 19/02/23 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Rotinas utilizadas para pagamento de fornecedores          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

/***************************************************
PONTO DE ENTRADA PARA FILTRAR REGISTROS NO BORDERÔ DE PAGAMENTOS
***************************************************/
User Function F240FIL
	Local cRet := "!ALLTRIM(E2_TIPO) == 'PA' .AND. "
	If cModPgto $ "01/03/41" .AND. Aviso("Atenção","Filtrar apenas os títulos com dados bancários", {'Sim', 'Não'}) == 1
		If cModPgto == "01"
			cRet += "E2_FORBCO == '"+cPort240+"'"
		Else
			cRet += "!E2_FORBCO == '"+cPort240+"' .AND. !Empty(E2_FORBCO)"
		EndIf
	ElseIf cModPgto $ "30/31" .AND. Aviso("Atenção","Filtrar apenas os títulos com código de barras", {'Sim', 'Não'}) == 1
		If cModPgto == "30" .AND. cPort240 == "341"
			cRet += "LEFT(E2_CODBAR,3) == '341'"
		ElseIf cModPgto == "31" .AND. cPort240 == "341"
			cRet += "!LEFT(E2_CODBAR,3) == '341' .AND. !Empty(E2_CODBAR)"
		Else
			cRet += "!Empty(E2_CODBAR)"
		EndIf
	ElseIf cModPgto $ "45" .AND. Aviso("Atenção","Filtrar apenas os fornecedores com chave PIX", {'Sim', 'Não'}) == 1
		cRet += "E2_FORNECE $ '"+cCodForPix()+"'"
	Else
		cRet := "!E2_TIPO == 'PA'"
	EndIf
Return cRet

/***************************************************
FORNECEDORES COM CHAVE PIX CADASTRADA
***************************************************/
Static Function cCodForPix()
	Local sAlias    := GetNextAlias()
	Local sQuery    := ""
	Local cLstFor 	:= ""
	sQuery := "SELECT DISTINCT F72_COD FROM "+RETSQLNAME("F72")+" WHERE D_E_L_E_T_ = '' "
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,sQuery), sAlias,.T.,.T.)
	(sAlias)->(DbGoTop())
	While !(sAlias)->(EOF())
		cLstFor += IIF(EMPTY(cLstFor),"","/")+ALLTRIM((sAlias)->F72_COD)
		(sAlias)->(DbSkip())
	EndDo
	(sAlias)->(dbCloseArea())
	FErase(sAlias+GetDBExtension())
	FErase(sAlias+OrdBagExt())
Return cLstFor


/**************************************************
GATILHO QUE TRANSFORMA A LINHA DIGITAVEL EM CODIGO DE BARRAS
***************************************************/
User Function OB_LDIG()
Local i := 0
Local _cRetorno := CSTR := CCHAR := ""
Local NMULT := NMODULO := 0
Local CDIGITO := CDV1 := CDV2 := CDV3 := CCAMPO1 := CCAMPO2 := CCAMPO3 := ""
Local nVal := nCalc_DV1 := nCalc_DV2 := nCalc_DV3 := 0

	cStr := M->E2_LINDIG

	If Len(Alltrim(cStr))==48
		_cRetorno:=SUBSTR(cStr,1,11)+SUBSTR(cStr,13,11)+SUBSTR(cStr,25,11)+SUBSTR(cStr,37,11)	
	Else

		i := 0
		nMult   := 2
		nModulo := 0
		cChar   := SPACE(1)
		cDigito := SPACE(1)

		cDV1    := SUBSTR(cStr,10, 1)
		cDV2    := SUBSTR(cStr,21, 1)
		cDV3    := SUBSTR(cStr,32, 1)

		cCampo1 := SUBSTR(cStr, 1, 9)
		cCampo2 := SUBSTR(cStr,11,10)
		cCampo3 := SUBSTR(cStr,22,10)

		nMult   := 2
		nModulo := 0
		nVal    := 0

		// Calcula DV1
		For i := Len(cCampo1) to 1 Step -1
			cChar := Substr(cCampo1,i,1)
			If isAlpha(cChar)
				Help(" ", 1, "ONLYNUM")
				Return(_cRetorno)
			EndIf
			nModulo := Val(cChar)*nMult
			If nModulo >= 10
				nVal := NVAL + 1
				nVal := nVal + (nModulo-10)
			Else
				nVal := nVal + nModulo
			EndIf
			nMult := If(nMult==2,1,2)
		Next
		nCalc_DV1 := 10 - (nVal % 10)


		//Calcula DV2
		nMult   := 2
		nModulo := 0
		nVal    := 0

		For i := Len(cCampo2) to 1 Step -1
			cChar := Substr(cCampo2,i,1)
			If isAlpha(cChar)
				Help(" ", 1, "ONLYNUM")
				Return(_cRetorno)
			EndIf
			nModulo := Val(cChar)*nMult
			If nModulo >= 10
				nVal := nVal + 1
				nVal := nVal + (nModulo-10)
			Else
				nVal := nVal + nModulo
			EndIf
			nMult := If(nMult==2,1,2)
		Next
		nCalc_DV2 := 10 - (nVal % 10)


		// Calcula DV3
		nMult   := 2
		nModulo := 0
		nVal    := 0

		For i := Len(cCampo3) to 1 Step -1
			cChar := Substr(cCampo3,i,1)
			If isAlpha(cChar)
				Help(" ", 1, "ONLYNUM")
				Return(_cRetorno)
			EndIf
			nModulo := Val(cChar)*nMult
			If nModulo >= 10
				nVal := nVal + 1
				nVal := nVal + (nModulo-10)
			Else
				nVal := nVal + nModulo
			EndIf
			nMult := If(nMult==2,1,2)
		Next
		nCalc_DV3 := 10 - (nVal % 10)

		If nCalc_DV1 == 10
			nCalc_DV1 := 0
		EndIf
		If nCalc_DV2 == 10
			nCalc_DV2 := 0
		EndIf
		If nCalc_DV3 == 10
			nCalc_DV3 := 0
		EndIf

		If !(nCalc_DV1 == Val(cDV1) .and. nCalc_DV2 == Val(cDV2) .and. nCalc_DV3 == Val(cDV3) )
			Help(" ",1,"INVALCODBAR")
			Return(_cRetorno)
		EndIf

		_cRetorno := SUBSTR(cStr, 1, 4)+SUBSTR(cStr, 33, 1)+iif(Len(alltrim(SUBSTR(cStr, 34, 14)))<14,StrZero(Val(Alltrim(SUBSTR(cStr, 34, 14))),14),SUBSTR(cStr, 34, 14))+SUBSTR(cStr, 5, 5)+SUBSTR(cStr, 11, 10)+SUBSTR(cStr, 22, 10)

	Endif
Return(_cRetorno)
