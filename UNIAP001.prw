#include "rwmake.ch"
#include "Protheus.ch"
#include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} UNIAP001

Rotina para o cálculo e geração do controle do Rappel

@author ASRConsult - Allan Constantino Bonfim
@since  19/11/2021
@version P12
@return NIL

/*/
//-------------------------------------------------------------------
User Function UNIAP001()  
	
	Local _aArea  	 	:= GetArea() 
	Local _aAreaSA1   	:= SA1->(GetArea())
	Local _aAreaSE1   	:= SE1->(GetArea())
	Local _aTmpSE1		:= SE1->(GetArea())
	Local _nRecSF2 		:= PARAMIXB[1]
	Local _nRecSA1 		:= PARAMIXB[2]
	Local _lExecRot		:= GetNewPar("ES_UNIAP1A", .T.)
	Local _cTpNfVen		:= GetNewPar("ES_UNIAP1B", "NF") //Tipo do título da nota para o cálculo do Rappel
	Local _dDIRappel	:= dDatabase
	Local _dDFRappel	:= dDatabase
	Local _nVlRappel	:= 0
	Local _lRet			:= .T.
	Local _aSE1			:= {}
	Local _cTpTit		:= GetNewPar("ES_UNIAP1C", "AB-") //Tipo do título do cálculo do Rappel
	Local _aCpoSE1		:= {}
	Local _nX			:= 0
	Local _cCpoSE1		:= ""
	Local _nValTit		:= 0
	Local _cTitulo		:= ""
	Local _cMsgWf		:= ""
	Local _nValImp		:= 0

	If _lExecRot		
		DbSelectArea("SF2") 
		If !Empty(_nRecSF2)			
			SF2->(DbGoto(_nRecSF2))
		EndIf

		DbSelectArea("SA1")
		If !Empty(_nRecSA1)
			SA1->(DbGoto(_nRecSA1))
		EndIf

		_nVlRappel	:= SA1->A1_PRAPPEL		
		_dDIRappel	:= SA1->A1_VIGIRAP
		_dDFRappel	:= SA1->A1_VIGFRAP

		If Empty(_dDIRappel) .AND. !Empty(_dDFRappel)
			_dDIRappel := YearSub(dDatabase, 1)
		EndIf

		If !Empty(_dDIRappel) .AND. Empty(_dDFRappel)
			_dDFRappel := YearSum(dDatabase, 1)
		EndIf 

		If _nVlRappel > 0 .AND. (dDatabase >= _dDIRappel .AND. dDatabase <= _dDFRappel)		
			DbSelectArea("SE1")
			SE1->(DbSetOrder(2)) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

			If SE1->(DbSeek(xFilial("SE1")+SF2->F2_CLIENTE+SF2->F2_LOJA+Substr(SF2->F2_FILIAL,2,3)+SF2->F2_DOC))

				If !Empty(SE1->E1_FILORIG) 
					_cTitulo := "Filial: "+Alltrim(SE1->E1_FILORIG)+" - Nº "+Alltrim(SE1->E1_NUM)+" - Prefixo: "+ Alltrim(SE1->E1_PREFIXO)+" - Tipo: "+ Alltrim(SE1->E1_TIPO)
				Else
					_cTitulo := "Nº "+Alltrim(SE1->E1_NUM)+" - Prefixo: "+ Alltrim(SE1->E1_PREFIXO)+" - Tipo: "+ Alltrim(SE1->E1_TIPO)
				EndIf
				
				// Obtem todos os campos da SE1			
				//_aCpoSE1 := FWSX3Util():GetAllFields("SE1", .F.)
				
				aadd(_aCpoSE1, "E1_FILIAL")
				aadd(_aCpoSE1, "E1_NUM")
				aadd(_aCpoSE1, "E1_PREFIXO")
				aadd(_aCpoSE1, "E1_PARCELA")
				aadd(_aCpoSE1, "E1_TIPO")
				aadd(_aCpoSE1, "E1_NATUREZ")
				aadd(_aCpoSE1, "E1_CLIENTE")
				aadd(_aCpoSE1, "E1_LOJA")
				aadd(_aCpoSE1, "E1_NOMCLI")
				aadd(_aCpoSE1, "E1_EMISSAO")
				aadd(_aCpoSE1, "E1_VENCTO")
				aadd(_aCpoSE1, "E1_VENCREA")
				aadd(_aCpoSE1, "E1_VALOR")
				aadd(_aCpoSE1, "E1_HIST")
				aadd(_aCpoSE1, "E1_MOEDA")
				aadd(_aCpoSE1, "E1_PRAPPEL")
				aadd(_aCpoSE1, "E1_VRAPPEL")
				aadd(_aCpoSE1, "E1_PEDIDO")
								
				Begin Transaction
					If SA1->A1_IRAPPEL == "N"
						_nValImp := UNIAP01D(SF2->(Recno()))
					EndIf

					While 	!SE1->(EOF()) .and.; 
							SE1->(E1_FILORIG+E1_PREFIXO+E1_NUM+E1_CLIENTE+E1_LOJA) == SF2->(F2_FILIAL+Substr(F2_FILIAL,2,3)+F2_DOC+F2_CLIENTE+F2_LOJA)

						If Alltrim(SE1->E1_TIPO) $ _cTpNfVen							
							_aSE1 := {}

							If SA1->A1_IRAPPEL == "N"
								_nValTit := Round(((SE1->E1_VALOR - _nValImp) * _nVlRappel / 100), 2) //Desconto imposto ICMS ST
							Else
								_nValTit := Round((SE1->E1_VALOR * _nVlRappel / 100), 2)
							EndIf

							For _nX := 1 to Len(_aCpoSE1)
								_cCpoSE1 := "SE1->"+_aCpoSE1[_nX] 
								
								If Alltrim(_aCpoSE1[_nX]) == "E1_TIPO"
									aadd(_aSE1, {_aCpoSE1[_nX], _cTpTit, Nil})
								ElseIf Alltrim(_aCpoSE1[_nX]) == "E1_PRAPPEL"
									aadd(_aSE1, {_aCpoSE1[_nX], _nVlRappel, Nil})
								ElseIf Alltrim(_aCpoSE1[_nX]) == "E1_VRAPPEL"
									aadd(_aSE1, {_aCpoSE1[_nX], _nValTit, Nil})
								ElseIf Alltrim(_aCpoSE1[_nX]) == "E1_VALOR"
									aadd(_aSE1, {_aCpoSE1[_nX], _nValTit, Nil})						
								Else
									aadd(_aSE1, {_aCpoSE1[_nX], &(_cCpoSE1), Nil})
								EndIf
							Next 
							
							_aTmpSE1 := SE1->(GetArea())
							
							//Gera titulos	
							_lRet := UNIAP01A(3, _aSE1)						
							
							RestArea(_aTmpSE1)	

							If _lRet
								Reclock("SE1", .F.)
									SE1->E1_PRAPPEL := _nVlRappel
									SE1->E1_VRAPPEL	:= _nValTit
								SE1->(MsUnlock())
							Else
								_cMsgWf := "Ocorreu um erro na geração do título do Rappel ref. o título "+Alltrim(_cTitulo)+"."+ CRLF+"É necessário a inclusão manual do(s) título(s) do Rappel para todas as parcelas correspondentes no contas a receber."

								If SE1->(InTransact())
									DisarmTransaction()
								Endif
								
								Exit
							EndIf									
						EndIf

						SE1->(DbSkip())
					EndDo
				End Transaction	 
				
				If !_lRet
					UNIAP01B(_cMsgWf)	
				EndIf
			EndIf
		Endif
	EndIf

	RestArea(_aAreaSA1)
	RestArea(_aAreaSE1)
	RestArea(_aArea)
	
Return _lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} UNIAP01A

Execauto para a inclusão do contas a receber do Rappel

@author ASRConsult - Allan Constantino Bonfim
@since  19/11/2021
@version P12
@return NIL

/*/
//-------------------------------------------------------------------
Static Function UNIAP01A(_nOpcao, _aSE1Auto)

	Local _aArea 			:= GetArea()
	Local _lRet				:=.F.
	
	Private lMsErroAuto 	:= .F. // Determina se houve alguma inconsistencia na execucao da rotina em relacao aos

	Default _nOpcao			:= 0
	Default _aSE1Auto		:= {}

	
	If !Empty(_nOpcao) .AND. Len(_aSE1Auto) > 0 
		MsExecAuto({|x,y| FINA040(x,y)}, _aSE1Auto, _nOpcao)  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
				
		If lMsErroAuto
			_lRet := .F.
			MostraErro()
		Else
			_lRet := .T.
		EndIf
	EndIf
	
	RestArea(_aArea)

Return _lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} UNIAP01B
Geração do workflow com erro na geração do Rappel

@author ASRConsult - Allan Constantino Bonfim
@since  22/11/2021
@version P12
@return NIL

/*/
//-------------------------------------------------------------------
Static Function UNIAP01B(_cMsgWf)

	Local _aArea 	:= GetArea()
	Local _lRet		:=.F.
	Local _cMailWf	:= GetNewPar("ES_UNIAP1D", "") //E-mails separados por ;
	Local _cTitWf	:= ""
	Local _cTextWf 	:= ""
	Local _cAnexWf 	:= ""	

	Default _cMsgWf	:= ""


	If !Empty(_cMailWf)
		_cTitWf		:= "UNIAP001 - Notificação automática de erro na geração do título do Rappel"
		
		_cTextWf  	:= "====================================================="  + "<BR>"
		_cTextWf  	+= "<B>ERRO NA GERAÇÃO DO TÍTULO DO RAPPEL<BR>"
		_cTextWf  	+= "<B>Data do Processamento:</B> " + DTOC(date()) + "<BR>"
		_cTextWf  	+= "<B>Hora do Processamento:</B> " + TIME() + "<BR>"
		_cTextWf  	+= "====================================================="  + "<BR><BR>"
		_cTextWf  	+= Alltrim(_cMsgWf)+ "<BR><BR> "
		_cTextWf  	+= "====================================================="  + "<BR><BR>"
		
		_lRet := UNIAP01C(_cMailWf, _cTitWf, _cTextWf, _cAnexWf)
	EndIf

	RestArea(_aArea)

Return _lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} UNIAP01C

Rotina para o envio de e-mails

@author ASRConsult - Allan Constantino Bonfim
@since  22/11/2021
@version P12
@return NIL

/*/
//-------------------------------------------------------------------
Static Function UNIAP01C(cEmails, cTitulo, cTexto, cAnexo, cCCEmails, cCOEmails, cConta, cPass, cRemetente, cServer, nPorta, lSSL, lTSL, SMTPTime)

	Local oServer
	Local oMessage
	Local lRet			:= .T.
	Local aAnexos     	:= {}
	Local cTxtTMP     	:= ""
	Local i				:= 0
	Local cMessage 		:= ""

	Default cEmails		:= ""
	Default cTitulo		:= ""
	Default cTexto		:= ""
	Default cAnexo		:= ""
	Default cCCEmails	:= "" //E-mail Cópia
	Default cCOEmails	:= "" //E-mail Cópia Oculta
	Default cConta   	:= SuperGetMv("MV_RELACNT")
	Default cPass 		:= SuperGetMv("MV_RELPSW")
	Default cRemetente	:= SuperGetMv("MV_RELACNT")
	Default cServer    	:= Iif(!":"$SuperGetMv("MV_RELSERV"),SuperGetMv("MV_RELSERV"),SubStr(SuperGetMv("MV_RELSERV"),1,AT(":",SuperGetMv("MV_RELSERV"))-1))
	Default nPorta      := Val(iif(!":"$SuperGetMv("MV_RELSERV"),"587",SubStr(SuperGetMv("MV_RELSERV"),AT(":",SuperGetMv("MV_RELSERV"))+1,len(SuperGetMv("MV_RELSERV")))))
	Default lSSL       	:= SuperGetMv("MV_RELSSL")
	Default lTSL       	:= SuperGetMv("MV_RELTLS")
	Default SMTPTime   	:= SuperGetMv("MV_RELTIME")
   

	//Cria a conexão com o server STMP ( Envio de e-mail )
	oServer := tMailManager():New()
	oServer:SetUseSSL(lSSL)
	oServer:SetUseTLS(lTSL)
	oServer:Init( "", cServer, cConta, cPass, 0, nPorta)
	
	//seta um tempo de time out com servidor de 1min
	If oServer:SetSmtpTimeOut(SMTPTime) != 0
		cMessage := "Falha ao setar o time out do SMTP."+ CRLF   
		FWLogMsg("WARN", "", "UNIAP001", "UNIAP01C", "", "", cMessage, 0, 0)

		lRet := .F.
		Return lRet
	EndIf
   
	//realiza a conexão SMTP
	n:=oServer:SmtpConnect()
	cErro := oServer:GetErrorString(n)
	If n!= 0
		cMessage := "Falha ao conectar no SMTP."+ CRLF   
		FWLogMsg("WARN", "", "UNIAP001", "UNIAP01C", "", "", cMessage, 0, 0)

		lRet := .F.
		Return lRet
	EndIf
	// Alterado a posição da autenticação após conetcar no SMTP
	oServer:SMTPAuth(cConta, cPass)

	//Apos a conexão, cria o objeto da mensagem                             
	oMessage := tMailMessage():New()
   
	//Limpa o objeto
	oMessage:Clear()
   
	//Popula com os dados de envio
	oMessage:cFrom := cConta
	oMessage:cTo := cEmails
	
	If !Empty(cCCEmails)
		oMessage:cCc := cCCEmails
	EndIf
	
	If !Empty(cCOEmails)	
		oMessage:cBcc := cCOEmails
	EndIf
	
	oMessage:cSubject := cTitulo
	oMessage:cBody := cTexto
   
	//+----------------------------------------+   
	//|Adiciona um attach
	//+----------------------------------------+
	//Verifica se existem mais de um arquivo para ser adcionado
	//e adciona cada um idividualmente
	If !Empty(cAnexo)
		//Monta array de Anexos
		If AT(";",cAnexo)>0
			For i:=1 to Len(cAnexo)
				If Substr(cAnexo,i,1)==";"
					AADD(aAnexos,cTxtTmp)
					cTxtTmp := ""
				Else
					cTxtTMP += Substr(cAnexo,i,1)
				EndIF

				If i == Len(cAnexo) .AND. !Empty(cTxtTmp)
					AADD(aAnexos,cTxtTmp)
					cTxtTmp := ""
				EndIf
			Next
		
			For i:= 1 to Len(aAnexos)
				If oMessage:AttachFile(aAnexos[i]) < 0
					cMessage := "Erro ao atachar o arquivo."+ CRLF   
					FWLogMsg("WARN", "", "UNIAP001", "UNIAP01C", "", "", cMessage, 0, 0)

					Return .F.
				Else
					//adiciona uma tag informando que é um attach e o nome do arq
					oMessage:AddAtthTag( aAnexos[i])
				EndIf
			Next
		Else
			If oMessage:AttachFile( cAnexo ) < 0
				cMessage := "Erro ao atachar o arquivo."+ CRLF   
				FWLogMsg("WARN", "", "UNIAP001", "UNIAP01C", "", "", cMessage, 0, 0)

				Return .F.
			Else
				//adiciona uma tag informando que é um attach e o nome do arq
				oMessage:AddAtthTag(cAnexo)
			EndIf
		EndIf
	EndIf
   
	//Envia o e-mail
	n := oMessage:Send(oServer)

	cErro := oServer:GetErrorString(n)

	If n != 0
		cMessage := "Erro ao enviar o e-mail mensagem: "+cErro+ CRLF   
		FWLogMsg("WARN", "", "UNIAP001", "UNIAP01C", "", "", cMessage, 0, 0)
		
		lRet := .F.
	EndIf
   
  //Desconecta do servidor
	If oServer:SmtpDisconnect() != 0
		cMessage := "Erro ao disconectar do servidor SMTP."+ CRLF   
		FWLogMsg("WARN", "", "UNIAP001", "UNIAP01C", "", "", cMessage, 0, 0)
		
		lRet := .F.
		Return lRet
	EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} UNIAP01D

Rotina para a verificação do valor do imposto na parcela do Rappel

@author ASRConsult - Allan Constantino Bonfim
@since  28/12/2021
@version P12
@return NIL

/*/
//-------------------------------------------------------------------
Static Function UNIAP01D(_nRecSF2)

	Local aArea 		:= GetArea()
	Local nValRet		:= 0	
	Local cAliasTmp		:= GetNextAlias()
	Local cQuery 		:= ""

	Default _nRecSF2	:= 0

	If _nRecSF2 > 0
		cQuery := "SELECT F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_ICMSRET, "
		cQuery += "COUNT(DISTINCT E1_PARCELA) QTDPARC "
		cQuery += "FROM " + RetSqlName('SF2') + " SF2 (NOLOCK) "
		cQuery += "INNER JOIN " + RetSqlName('SE1') + " SE1 (NOLOCK) "
		cQuery += "ON (F2_FILIAL = E1_FILORIG AND F2_DOC = E1_NUM AND F2_SERIE = E1_PREFIXO "
		cQuery += "AND F2_CLIENTE = E1_CLIENTE AND F2_LOJA = E1_LOJA AND SF2.D_E_L_E_T_ = '') "
		cQuery += "WHERE SE1.D_E_L_E_T_ = '' "
		cQuery += "AND SF2.R_E_C_N_O_ = "+ ALLTRIM(cValtoChar(_nRecSF2)) +" "
		cQuery += "GROUP BY F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_ICMSRET "

		cQuery := ChangeQuery(cQuery)
		MPSysOpenQuery(cQuery, cAliasTmp)

		If !(cAliasTmp)->(EOF()) 
			nValRet := (cAliasTmp)->F2_ICMSRET / (cAliasTmp)->QTDPARC
		EndIf
	EndIf 

	RestArea(aArea)

Return nValRet 
