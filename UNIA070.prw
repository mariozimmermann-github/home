#Include 'Totvs.ch'

/*Posicao array aArq*/
#Define NA_NOMEARQ 	1

/*Posicao array aLinha*/
#Define ACAO            01   
#Define COD_TABELA      02   
#Define TIPO_TABELA     03
#Define IDA_E_VOLTA     04
#Define INI_VALIDADE    05
#Define FIN_VALIDADE    06
#Define PRIORIDADE      07
#Define CID_ORIGEM      08
#Define REG_ORIGEM      09
#Define REMETENTE       10
#Define CID_DESTINO     11
#Define REG_DESTINO     12
#Define DESTINATARIO    13
#Define TIPO_OPER       14
#Define TIPO_DE_VEICULO 15
#Define TRANSP          16    
#Define MODAL           17
#Define CLASS_FRETE     18
#Define TIPO_PRAZO      19
#Define PRAZO           20

#Define NTOTCOL         20

/*/{Protheus.doc} UNIA070
    Importar cadastro prazo de entrega 
    @type  User Function
    @author Original TRS
    @author Denis Rodrigues
    @since 26/01/2022
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    @see (links_or_references)
/*/
User Function UNIA070()

	Local aInfo		:= {}
	Local cDescRot	:= ""
	Local cCadastro	:= "Importar Cadastro Prazo de Entrega"
   	Local cPerg 	:= PadR( "UNIA070", 10 )	
   	Local cRotArq	:= ""
	Local bProcess	:= {||}
	Local oProcess 
	
	Private __nnLock := 0 
	Private __ccArq  := ""

	AjustaSX1( cPerg )

	Pergunte( cPerg, .F. )

	cRotArq	:= "UNIA070"
	cRotArq += AllTrim( cEmpAnt )
	cRotArq += AllTrim( cFilAnt )

	If !RotLock( cRotArq, 10 )   
        Alert("Essa rotina só pode ser executada apenas por 1 usuário!")
    Else

		aAdd( aInfo, { "Cancelar", { |oPanelCenter| oPanelCenter:oWnd:End() }, "CANCEL"  })

		bProcess := {|oProcess| oProcess:SaveLog("Inicio do processo"),;
								FWMsgRun(, {|oSay| A050Proc( oSay ) }, "Aguarde", "Processando..."),;
								oProcess:SaveLog("Fim do processo") }

		cDescRot := " Este programa tem o objetivo, importar cadastro prazo de entrega,"
		cDescRot += " no formato CSV."

		oProcess := TNewProcess():New( "UNIA070", cCadastro, bProcess, cDescRot, cPerg, aInfo, .T., 5, "Aguarde processando...", .F. )
		
    	RotUnlock()

	EndIf

Return

/*/{Protheus.doc} A050Proc
    Processamento da rotina
    @type  User Function
    @author TRS
    @since 26/01/2022
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    @see (links_or_references)
/*/
Static Function A050Proc( oSay )  

    Local aArq      := {}
    Local aLinha    := {}
    Local lOk       := .T.
    Local lFirst    := .T.
    Local lSucesso  := .T.
	Local cMvDirRet := AllTrim( MV_PAR01 )
    Local nArq      := 0
    Local nZ        := 0

	If Empty( cMvDirRet )
	
		lOk := .F.
		AutoGrLog("Não existe arquivo a importar. Verifique o parametro.")
	
	EndIf
	 
	If lOk
	
		If Upper( Right( cMvDirRet, 3 ) ) = "CSV" 
			If !File( cMvDirRet )
				lOk := .F.
			Else	
				aArq := { { Upper( SubStr( cMvDirRet, RAt( "\", cMvDirRet ) + 1 ) ) , .T., "", "", "" } }
				cMvDirRet := SubStr( cMvDirRet, 1, RAt( "\", cMvDirRet ) )	
			EndIf
		Else
			
			cMvDirRet := IIf( Right( cMvDirRet, 1 ) <> "\",  cMvDirRet + "\", cMvDirRet )
			
			If Len( aArq := Directory( cMvDirRet + "*.CSV" ) ) < 0
					
				lOk := .F.
		
				AutoGrLog("Não existe arquivo a importar.")
				AutoGrLog("Verifique se contem arquivo na pasta (" + cMvDirRet + ").")
	   	
		   	EndIf
		   			   	
		EndIf
		
   	EndIf

    If lOk

        GUB->( dbSetOrder(1) )    
        GUN->( dbSetOrder(1) )    
        GU3->( dbSetOrder(1) )    
        GU7->( dbSetOrder(1) )    
        GU9->( dbSetOrder(1) )    
        GV3->( dbSetOrder(1) )    
        GV4->( dbSetOrder(1) )    
        GU1->( dbSetOrder(1) )    
        GU3->( dbSetOrder(1) )    

   		// Ordem por nome do arquivo
		aSort( aArq,,,{|x,y| x[NA_NOMEARQ] < y[NA_NOMEARQ]} ) 		
	
		For nArq := 1 To Len( aArq )
		
            /*/
            Colunas arquivo CSV

            GUN_CODTAB – COD TABELA
            GUN_TPTAB – TIPO TABELA
            GUN_DUPSEN – IDA  E VOLTA
            GUN_DATDE – INI VALIDADE
            GUN_DATATE – FIN VALIDADE
            GUN_PRIOR - PRIORIDADE

            GUN_NRCIOR - CID ORIGEM
            GUN_NRREOR – REG ORIGEM
            GUN_CDREM - REMETENTE

            GUN_NRCIDS – CID DESTINO
            GUN_NRREDS – REG DESTINO
            GUN_CDDEST – DESTINATARIO

            GUN_CDTPOP – TIPO OPER
            GUN_CDTPVC – TIPO DE VEICULO
            GUN_CDTRP – TRANSP
            GUN_MODAL – MODAL 
            GUN_CDCLFR – CLASS FRETE
            GUN_TPPRAZ – TIPO PRAZO
            GUN_PRAZO - PRAZO
            /*/ 

			AutoGrLog( "******************************************************" )  
			AutoGrLog( "Arquivo: " + aArq[nArq][NA_NOMEARQ] )
            AutoGrLog( "     " )
						
			//Verifica se o Arquivo esta Disponivel para uso
			If FT_FUSE( cMvDirRet + aArq[nArq][NA_NOMEARQ] ) < 0
	
				AutoGrLog( "Nao foi possivel abri-lo." )
				AutoGrLog( "Erro: "+ cValToChar( FError() ) )
				AutoGrLog( "" )
				
				Loop
				
			EndIf 
			
           	lFirst 	:= .T.
			aLinha  := {}
            xLinha  := ""
			
			FT_FGOTOP()
			
            lSucesso:= ( FT_FEOF() = .F. )

			While !FT_FEOF()
		        
                lOk    := .T.
                aLinha := {}

				xLinha := Val( xLinha )
                xLinha ++
                xLinha := cValToChar( xLinha )

                cLinha := AllTrim( FT_FREADLN() )

                If Empty( cLinha )
                    AutoGrLog( "Linha: "+xLinha+" Erro: Linha em branco" )
                    lOk := .F.
                    lSucesso := .F.
                    FT_FSKIP()
                    Loop
                Else
                    
                    aLinha := Separa( cLinha, ";", .T. )

                    If lFirst
                        lFirst := .F.
                        FT_FSKIP()
                        Loop
                    EndIf

                    If Len( aLinha ) < NTOTCOL
                        AutoGrLog( "Linha: "+xLinha+" Erro: A quantidade de coluna não pode ser inferior a " + cvaltochar(NTOTCOL) )
                        lOk := .F.
                        lSucesso := .F.
                        FT_FSKIP()
                        Loop
                    EndIf

				EndIf

                nZ := 0    
                aEval( aLinha, {|z| nZ++,  aLinha[nZ] := Upper( AllTrim(z) )  } )

                If aLinha[ACAO] == 'I'//Inclusao
                    
                    If !Empty( aLinha[COD_TABELA] )
                        AutoGrLog( "Linha: "+xLinha+" Coluna: ACAO Erro: Para ação I, o codigo da tabela não precisa ser preenchida" )
                        lOk := .F.
                    EndIf

                EndIf

                If aLinha[ACAO] $ 'A/E'//Alterar ou Excluir
                    
                    If !GUN->( MsSeek(xFilial("GUN")+aLinha[COD_TABELA]) )
                        AutoGrLog( "Linha: "+xLinha+" Coluna: ACAO Erro: Para ação A ou E, a tabela precisa existir no cadastro." )
                        lOk := .F.
                    EndIf

                EndIf

                If !( aLinha[TIPO_TABELA] $ "1234") .Or. Len(aLinha[TIPO_TABELA]) > 1
                    AutoGrLog( "Linha: "+xLinha+" Coluna: TIPO TABELA Erro: Valores permitido para essa coluna 1=Prazo;2=Distância;3=Quebra Peso;4=Frete Referência" )
                    lOk := .F.
                EndIf

                If !( aLinha[IDA_E_VOLTA] $ "12") .Or. Len(aLinha[IDA_E_VOLTA]) > 1
                    AutoGrLog( "Linha: "+xLinha+" Coluna: IDA E VOLTA Erro: Valores permitido para essa coluna 1=Sim;2=Não" )
                    lOk := .F.
                EndIf

                If Empty( aLinha[INI_VALIDADE] ) .Or. Empty( aLinha[FIN_VALIDADE] )
                    AutoGrLog( "Linha: "+xLinha+" Coluna: INI VALIDADE / FIM VALIDADE Erro: Valor não permitido para essa coluna" )
                    lOk := .F.
                EndIf

                If Empty( aLinha[CID_ORIGEM] )  .And. Empty( aLinha[REG_ORIGEM] ) .And. Empty( aLinha[REMETENTE] )

                    AutoGrLog( "Linha: "+xLinha+" Coluna: CID ORIGEM / REG ORIGEM / REMETENTE  Erro: Valor não permitido para essa coluna" )
                    lOk := .F.

                ElseIf !Empty( aLinha[CID_ORIGEM] )  
                
                    If !Empty( aLinha[REG_ORIGEM] ) .Or. !Empty( aLinha[REMETENTE] )
                        AutoGrLog( "Linha: "+xLinha+" Coluna: CID ORIGEM / REG ORIGEM / REMETENTE  Erro: Preencha somente uma dessas colunas" )
                        lOk := .F.
                    EndIf

                    If !GU7->( MsSeek( xFilial("GU7") + aLinha[CID_ORIGEM] ) )
                        AutoGrLog( "Linha: "+xLinha+" Coluna: CID ORIGEM Erro: Valor não encontrado na tabela correspondente" )
                        lOk := .F.
                    EndIf

                ElseIf !Empty( aLinha[REG_ORIGEM] )

                    If !Empty( aLinha[CID_ORIGEM] ) .Or. !Empty( aLinha[REMETENTE] )
                        AutoGrLog( "Linha: "+xLinha+" Coluna: CID ORIGEM / REG ORIGEM / REMETENTE  Erro: Preencha somente uma dessas colunas" )
                        lOk := .F.
                    EndIf

                    If !GU9->( MsSeek( xFilial("GU9") + aLinha[REG_ORIGEM] ) )
                        AutoGrLog( "Linha: "+xLinha+" Coluna: REG ORIGEM Erro: Valor não encontrado na tabela correspondente" )
                        lOk := .F.
                    EndIf

                ElseIf !Empty( aLinha[REMETENTE] )

                    If !Empty( aLinha[CID_ORIGEM] ) .Or. !Empty( aLinha[REG_ORIGEM] )
                        AutoGrLog( "Linha: "+xLinha+" Coluna: CID ORIGEM / REG ORIGEM / REMETENTE  Erro: Preencha somente uma dessas colunas" )               
                        lOk := .F.
                    EndIf

                    If !GU3->( MsSeek( xFilial("GU3") + aLinha[REMETENTE] ) )
                        AutoGrLog( "Linha: "+xLinha+" Coluna: REMETENTE Erro: Valor não encontrado na tabela correspondente" )
                        lOk := .F.
                    EndIf
                
                EndIf

                If Empty( aLinha[CID_DESTINO] )  .And. Empty( aLinha[REG_DESTINO] ) .And. Empty( aLinha[DESTINATARIO] )

                    AutoGrLog( "Linha: "+xLinha+" Coluna: CID DESTINO / REG DESTINO / DESTINATARIO  Erro: Valor não permitido para essa coluna" )
                    lOk := .F.

                ElseIf !Empty( aLinha[CID_DESTINO] )  
                
                    If !Empty( aLinha[REG_DESTINO] ) .Or. !Empty( aLinha[DESTINATARIO] )
                        AutoGrLog( "Linha: "+xLinha+" Coluna: CID DESTINO / REG DESTINO / DESTINATARIO  Erro: Preencha somente uma dessas colunas" )
                        lOk := .F.
                    EndIf

                    If !GU7->( MsSeek( xFilial("GU7") + aLinha[CID_DESTINO] ) )
                        AutoGrLog( "Linha: "+xLinha+" Coluna: CID DESTINO Erro: Valor não encontrado na tabela correspondente" )
                        lOk := .F.
                    EndIf

                ElseIf !Empty( aLinha[REG_DESTINO] )

                    If !Empty( aLinha[CID_DESTINO] ) .Or. !Empty( aLinha[DESTINATARIO] )
                        AutoGrLog( "Linha: "+xLinha+" Coluna: CID DESTINO / REG DESTINO / DESTINATARIO  Erro: Preencha somente uma dessas colunas" )
                        lOk := .F.
                    EndIf

                    If !GU9->( MsSeek( xFilial("GU9") + aLinha[REG_DESTINO] ) )
                        AutoGrLog( "Linha: "+xLinha+" Coluna: REG DESTINO Erro: Valor não encontrado na tabela correspondente" )
                        lOk := .F.
                    EndIf

                ElseIf !Empty( aLinha[DESTINATARIO] )

                    If !Empty( aLinha[CID_DESTINO] ) .Or. !Empty( aLinha[REG_DESTINO] )
                        AutoGrLog( "Linha: "+xLinha+" Coluna: CID DESTINO / REG DESTINO / DESTINATARIOS  Erro: Preencha somente uma dessas colunas" )               
                        lOk := .F.
                    EndIf

                    If !GU3->( MsSeek( xFilial("GU3") + aLinha[DESTINATARIO] ) )
                        AutoGrLog( "Linha: "+xLinha+" Coluna: DESTINATARIO Erro: Valor não encontrado na tabela correspondente" )
                        lOk := .F.
                    EndIf

                EndIf

                If !GV4->( MsSeek( xFilial("GV4") + aLinha[TIPO_OPER] ) )
                   AutoGrLog( "Linha: "+xLinha+" Coluna: TIPO OPER Erro: Valor não encontrado na tabela correspondente" )
                   lOk := .F.
                EndIf
                // alterado por Daniel 14/07/2021 solicitdo por Geovir.
                //If !GV3->( MsSeek( xFilial("GV3") + aLinha[TIPO_DE_VEICULO] ) )
                //   AutoGrLog( "Linha: "+xLinha+" Coluna: TIPO DE VEICULO Erro: Valor não encontrado na tabela correspondente" )
                //   lOk := .F.
                //EndIf

                If !GU3->( MsSeek( xFilial("GU3") + aLinha[TRANSP] ) )
                   AutoGrLog( "Linha: "+xLinha+" Coluna: TRANSP Erro: Valor não encontrado na tabela correspondente" )
                   lOk := .F.
                EndIf  

                If !( aLinha[MODAL] $ "1234567") .Or. Len(aLinha[MODAL]) > 1
                    AutoGrLog( "Linha: "+xLinha+" Coluna: MODAL Erro: Valores permitido para essa coluna 1=Indiferente;2=Terrestre;3=Ferroviario;4=Aereo;5=Fluvial;6=por Conducto;7=Multimodal" )
                    lOk := .F.
                EndIf

                If !GUB->( MsSeek( xFilial("GUB") + aLinha[CLASS_FRETE] ) )
                   AutoGrLog( "Linha: "+xLinha+" Coluna: CLASS FRETE Erro: Valor não encontrado na tabela correspondente" )
                   lOk := .F.
                EndIf

                If !( aLinha[TIPO_PRAZO] $ "012") .Or. Len(aLinha[TIPO_PRAZO]) > 1
                    AutoGrLog( "Linha: "+xLinha+" Coluna: TIPO PRAZO Erro: Valores permitido para essa coluna 0=Dias Uteis;1=Dias Corridos;2=Horas" )
                    lOk := .F.
                EndIf

                If !lOk
                    lSucesso := .F.
                Else

                    dbSelectArea("GUN")
                    If aLinha[ACAO] == 'E'
                        Reclock("GUN", .F.)
                            dbDelete()
                        MsUnLock()
                    Else

                        If aLinha[ACAO] == 'I'
                            Reclock("GUN", .T.)
                        Else
                            Reclock("GUN", .F.)
                        EndIf

                            GUN->GUN_FILIAL := xFilial("GUN")

                            If aLinha[ACAO] == 'I'
                                
                                GUN->GUN_CODTAB := GetSXENum("GUN","GUN_CODTAB")                                                                                                   
                                GUN->GUN_CRIUSU := RetCodUsr()
                                GUN->GUN_CRIDAT := Date() 

                                ConfirmSX8()

                            Else
                                GUN->GUN_CODTAB := aLinha[COD_TABELA]
                                GUN->GUN_ALTUSU := RetCodUsr()
                                GUN->GUN_ALTDAT := Date()
                            EndIf

                            GUN->GUN_TPTAB  := aLinha[TIPO_TABELA]
                            GUN->GUN_DUPSEN := aLinha[IDA_E_VOLTA]
                            GUN->GUN_DATDE  := CToD( aLinha[INI_VALIDADE] )
                            GUN->GUN_DATATE := CToD( aLinha[FIN_VALIDADE] )
                            GUN->GUN_PRIOR  := Val( aLinha[PRIORIDADE] )

                            GUN->GUN_NRCIOR := aLinha[CID_ORIGEM]
                            GUN->GUN_NRREOR := aLinha[REG_ORIGEM]
                            GUN->GUN_CDREM  := aLinha[REMETENTE]

                            GUN->GUN_NRCIDS := aLinha[CID_DESTINO]
                            GUN->GUN_NRREDS := aLinha[REG_DESTINO]
                            GUN->GUN_CDDEST := aLinha[DESTINATARIO]

                            GUN->GUN_CDTPOP := aLinha[TIPO_OPER]
                            GUN->GUN_CDTPVC := aLinha[TIPO_DE_VEICULO]
                            GUN->GUN_CDTRP  := aLinha[TRANSP]
                            GUN->GUN_MODAL  := aLinha[MODAL] 
                            GUN->GUN_CDCLFR := aLinha[CLASS_FRETE]
                            GUN->GUN_TPPRAZ := aLinha[TIPO_PRAZO]
                            GUN->GUN_PRAZO  := Val( aLinha[PRAZO] )

                            //campos com inicializador padrão
                            GUN->GUN_ENVIAE := "1"
                            GUN->GUN_STATUS := "0"
                            GUN->GUN_IMPINC := "1"
                            GUN->GUN_TPREF  := "1"
                            GUN->GUN_PERVIG := "1"
                            GUN->GUN_TPFREQ := "1"
                            GUN->GUN_RECOR  := "0"
                            GUN->GUN_SOLMOD := "1"
                            GUN->GUN_SOLSIT := "1"
                            GUN->GUN_WFSIT  := "0"

                        MsUnLock()

                    EndIf

                EndIf

				FT_FSKIP()
				
			EndDo

			FT_FUSE()

		    If lSucesso
		        AutoGrLog( "Importado com sucesso!" )		    	
		    EndIf

        Next

    EndIf

    MostraErro()

Return

/*/{Protheus.doc} AjustaSX1
    Grupo de perguntas
    @type  User Function
    @author TRS
    @since 15/09/2020
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    @see (links_or_references)
/*/
Static Function AjustaSX1( cPerg )

	Local aPerg := {}
	Local nX    := 0 
		
	//                           1        2             3       4     5   6       7       8    9     10     11    12    13    14     15
	//.. Perguntas-- Grupo    Ordem    Perguntas     Variavel  Tipo  Tam Dec   Variavel  GSC   F3   Def01  Def02 Def03 Def04 Def05  Valid 
	aAdd( aPerg , { "01", "Arquivo(s) a importar ?"	, "mv_ch0", "C", 99 , 0 ,"MV_PAR01","G","DIR" ,""     ,""            ,"" ,""  ,""   ,"" } )
	
	dbSelectArea("SX1")                
	dbSetOrder(1)
	
	For nX := 1 To Len( aPerg )
		
		If !dbSeek( cPerg + aPerg[nX,1] )
		
			RecLock("SX1",.T.)
				SX1->X1_GRUPO	:= cPerg 
				SX1->X1_ORDEM	:= aPerg[nX][01]
				SX1->X1_PERGUNT := aPerg[nX][02] 
				SX1->X1_VARIAVL	:= aPerg[nX][03]
				SX1->X1_TIPO	:= aPerg[nX][04] 
				SX1->X1_TAMANHO	:= aPerg[nX][05]
				SX1->X1_DECIMAL	:= aPerg[nX][06] 
				SX1->X1_VAR01	:= aPerg[nX][07]
				SX1->X1_GSC		:= aPerg[nX][08]
				SX1->X1_F3		:= aPerg[nX][09]
				SX1->X1_Def01	:= aPerg[nX][10] 
				SX1->X1_Def02	:= aPerg[nX][11]
				SX1->X1_Def03	:= aPerg[nX][12] 
				SX1->X1_Def04	:= aPerg[nX][13]
				SX1->X1_Def05	:= aPerg[nX][14] 
				SX1->X1_Valid	:= aPerg[nX][15]
			MsUnlock()                       
		
		EndIf
	Next                                        

Return

/*/{Protheus.doc} RotLock
    Trava para operação critica 
    @type  User Function
    @author Julio Witwer
    @since 
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    @see (links_or_references)
/*/
Static Function RotLock( cKey, nTentativas )

	__ccArq := cKey+".LCK"
	
	nCont := 1     
	
	While (__nnLock := fcreate(__ccArq)) == -1
	    If KillApp()
	        conout("RotLock abort on "+procname(1))
	        __nnLock := -1
	    Endif      
	    nCont++
	    If nCont > nTentativas   
	    	
	    	Conout( cKey + " - RotLock excedeu tentativas")		
	    	Exit
	    Endif
	    sleep(1000)
	Enddo
	
Return( __nnLock <> -1 )                                                                            

/*/{Protheus.doc} RotUnlock()
    Destrava a operacao critica 
    @type  User Function
    @author Julio Witwer
    @since 
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    @see (links_or_references)
/*/
Static Function RotUnlock()
	
	If __nnLock != -1
	    fclose(__nnLock)
	    ferase(__ccArq)
	Endif
	
Return .T.
