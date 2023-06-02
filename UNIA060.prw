#Include 'Totvs.ch'

/*Posicao array aArq*/
#Define NA_NOMEARQ 	1

/*Posicao array aLinha*/
#Define NRREG       01   
#Define NMREG       02   
#Define CDUF        03
#Define CDPAIS      04
#Define SIGLA       05
#Define SIT         06
#Define DEMCID      07
#Define NRCID       08

#Define NTOTCOL     08

/*/{Protheus.doc} UNIA060
    Importar Cadastro Regiões
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
User Function UNIA060()

	Local aInfo		:= {}
	Local cDescRot	:= ""
	Local cCadastro	:= "Importar Cadastro Regiões"
   	Local cPerg 	:= PadR( "UNIA060", 10 )	
   	Local cRotArq	:= ""
	Local bProcess	:= {||}
	Local oProcess 
	
	Private __nnLock := 0 
	Private __ccArq  := ""

	AjustaSX1( cPerg )

	Pergunte( cPerg, .F. )

	cRotArq	:= "UNIA060"
	cRotArq += AllTrim( cEmpAnt )
	cRotArq += AllTrim( cFilAnt )

	If !RotLock( cRotArq, 10 )   
        Alert("Essa rotina só pode ser executada apenas por 1 usuário!")
    Else

		aAdd( aInfo, { "Cancelar", { |oPanelCenter| oPanelCenter:oWnd:End() }, "CANCEL"  })

		bProcess := {|oProcess| oProcess:SaveLog("Inicio do processo"),;
								FWMsgRun(, {|oSay| A060Proc( oSay ) }, "Aguarde", "Processando..."),;
								oProcess:SaveLog("Fim do processo") }

		cDescRot := " Este programa tem o objetivo, importar cadastro de regiões,"
		cDescRot += " no formato CSV."

		oProcess := TNewProcess():New( "UNIA060", cCadastro, bProcess, cDescRot, cPerg, aInfo, .T., 5, "Aguarde processando...", .F. )
		
    	RotUnlock()

	EndIf

Return

/*/{Protheus.doc} A060Proc
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
Static Function A060Proc( oSay )

    Local aArq      := {}
    Local aLinha    := {}
    Local lOk       := .T.
    Local lFirst    := .T.
    Local lSucesso  := .T.
	Local cMvDirRet := AllTrim( MV_PAR01 )
    Local cNrReg    := ""
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

   		// Ordem por nome do arquivo
		aSort( aArq,,,{|x,y| x[NA_NOMEARQ] < y[NA_NOMEARQ]} ) 		
	
		For nArq := 1 To Len( aArq )
		
            /*/
                Colunas arquivo CSV
                GU9_NRREG - REGIAO - Existchav("GU9")                                                                                                                
                GU9_NMREG - NOME REGIAO -  Texto() .AND. NaoVazio()                                                                                                       
                GU9_CDUF  - ESTADO -  ExistCpo('SX5','12'+M->GU9_CDUF)                                                                                               
                GU9_CDPAIS - PAIS  ExistCpo("SYA",M->GU9_CDPAIS)                                                                                                  
                GU9_SIGLA  - SIGLA -  NaoVazio()                                                                                                                     
                GU9_SIT    - SITUACAO - Pertence("12")   
                GU9_DEMCID - DEMAIS CIDADES -   Pertence("12")                                                                                                                
                GUA_NRCID - CIDADE - IF(!INCLUI,POSICIONE("GU7",1,XFILIAL("GU7")+GUA->GUA_NRCID,"GU7_NMCID"),"")                                                     
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
            cNrReg  := ""
			
			FT_FGOTOP()
			
            lSucesso := ( FT_FEOF() = .F. )

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

                    If Len( aLinha ) <> NTOTCOL
                        AutoGrLog( "Linha: "+xLinha+" Erro: A quantidade de coluna não pode ser inferior a " + cvaltochar(NTOTCOL) )
                        lOk := .F.
                        lSucesso := .F.
                        FT_FSKIP()
                        Loop
                    EndIf

				EndIf

                nZ := 0    
                aEval( aLinha, {|z| nZ++,  aLinha[nZ] := Upper( AllTrim(z) )  } )

                If Empty( aLinha[NRREG] ) .Or. Len( aLinha[NRREG] ) < TamSX3("GU9_NRREG")[1]    
                    AutoGrLog( "Linha: "+xLinha+" Coluna: REGIAO Erro: Coluna em branco ou seu conteudo é menor que o permitido" )
                    lOk := .F.
                EndIf

                If Empty( aLinha[NMREG] )    
                    AutoGrLog( "Linha: "+xLinha+" Coluna: NOME REGIAO Erro: Coluna em branco ou somente com numero" )
                    lOk := .F.
                EndIf

                If !ExistCpo('SX5','12'+aLinha[CDUF])
                    AutoGrLog( "Linha: "+xLinha+" Coluna: ESTADO Erro: Valor não encontrado na tabela correspondente" )
                    lOk := .F.
                EndIf 

                If !ExistCpo("SYA",aLinha[CDPAIS])
                    AutoGrLog( "Linha: "+xLinha+" Coluna: PAIS Erro: Valor não encontrado na tabela correspondente" )
                    lOk := .F.
                EndIf 

                If Empty( aLinha[SIGLA] )
                    AutoGrLog( "Linha: "+xLinha+" Coluna: SIGLA Erro: Coluna não pode ser branco" )
                    lOk := .F.
                EndIf

                If !( aLinha[SIT] $ "12")
                    AutoGrLog( "Linha: "+xLinha+" Coluna: SIT Erro: Valores permitido para coluna 1=Ativo e 2=Inativo" )
                    lOk := .F.
                EndIf

                If !( aLinha[DEMCID] $ "12")
                    AutoGrLog( "Linha: "+xLinha+" Coluna: DEMCID Erro: Valores permitido para coluna 1=Sim e 2=Nao" )
                    lOk := .F.
                EndIf

                GU7->( dbSetOrder(1) )    
                If !GU7->( MsSeek( xFilial("GU7") + aLinha[NRCID] ) )
                   AutoGrLog( "Linha: "+xLinha+" Coluna: NRCID Erro: Valor não encontrado na tabela correspondente" )
                   lOk := .F.
                EndIf

                If !lOk
                    lSucesso := .F.
                Else

                    If cNrReg <> aLinha[NRREG]
                        
                        cNrReg := aLinha[NRREG]

                        dbSelectArea("GU9")
                        GU9->( dbSetOrder(1) )    
                        If !GU9->( MsSeek( xFilial("GU9") + aLinha[NRREG] ) )
                            Reclock("GU9", .T.)
                        Else
                            Reclock("GU9", .F.)
                        EndIf
                            GU9->GU9_FILIAL := xFilial("GU9")
                            GU9->GU9_NRREG  := aLinha[NRREG] 
                            GU9->GU9_NMREG  := aLinha[NMREG]
                            GU9->GU9_CDUF   := aLinha[CDUF]
                            GU9->GU9_CDPAIS := aLinha[CDPAIS]
                            GU9->GU9_SIGLA  := aLinha[SIGLA]
                            GU9->GU9_SIT    := aLinha[SIT]
                            GU9->GU9_DEMCID := aLinha[DEMCID]
                        MsUnLock()
                    EndIf                   

                    dbSelectArea("GUA")
                    GUA->( dbSetOrder(1) )    
                    If !GUA->( MsSeek( xFilial("GUA") + aLinha[NRREG] + aLinha[NRCID] ) )
                        Reclock("GUA", .T.)
                            GUA->GUA_FILIAL:= xFilial("GUA")
                            GUA->GUA_NRREG := aLinha[NRREG]
                            GUA->GUA_NRCID := aLinha[NRCID]
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
    @since 26/01/2022
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
