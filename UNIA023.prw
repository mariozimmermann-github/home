#include 'rwmake.ch'
#include 'totvs.ch'
#include 'topconn.ch'

/*
+-----------+-----------+-------+------------------------------------------------------+------+----------+
| Funcao    | unia023   | Autor | Manoel M Mariante                                    | Data |dez/2021  |
|-----------+-----------+-------+------------------------------------------------------+------+----------|
| Descricao | cadastro de regras de decrescimo de comissao                                               |
|           |                                                                                            |
|           |                                                                                            |
|-----------+--------------------------------------------------------------------------------------------|
| Sintaxe   | executado                                                                                  |
+-----------+--------------------------------------------------------------------------------------------+
*/

User Function unia023()

	Private _TABPESQ 	:='SZ1'
	Private _CHAVPESQ	:='Z1_TABELA'
	Private _ORDPESQ	:=1
	Private aCabec		:={}
	Private _TITULO		:= posicione('SX2',1,_TABPESQ,'X2_NOME')
	Private aRotina		:= {}

	dbSelectArea( _TABPESQ )

	Aadd(aRotina,{ 'Pesquisar' , 'AxPesqui'       , 0, 1 })
	Aadd(aRotina,{ 'Visualizar', 'u_funia023(2)'  , 0, 2 })
	Aadd(aRotina,{ 'Incluir'   , 'u_funia023(3)'  , 0, 3 })
	Aadd(aRotina,{ 'Alterar'   , 'u_funia023(4)'  , 0, 4 })
	Aadd(aRotina,{ 'Excluir'   , 'u_funia023(5)'  , 0, 5 })

	dbSetOrder( 1 )
	dbGoTop()

	mBrowse( 06, 01, 22, 75, _TABPESQ,,,,,,)

Return

//---------------------------------------------------------------------------------------------
User Function funia023(nOpcX)
//---------------------------------------------------------------------------------------------

	Local _ni			:=0
	Private _XVISUAL	:= .f.
	Private _XINCLUI	:= .f.
	Private _XALTERA	:= .f.
	Private _XEXCLUI	:= .f.
	Private _xCOPIA		:= .f.
	Private aHeader		:={}
	Private aCols 		:={}
	Private aDelRecno	:={}
	Private aGetsGD		:={}
	Private aObrigat	:={}
	//variaveis do cabec
	Private CZ1TABELA	:=criavar(_CHAVPESQ,.f.)
	Private CZ1DESC		:=CRIAVAR('DA0_DESCRI',.F.)

	Do Case
	Case nOpcX == 2
		_XVISUAL	:= .t.
	Case nOpcX == 3
		_XINCLUI	:= .t.
	Case nOpcX == 4
		_XALTERA	:= .t.
	Case nOpcX == 5
		_XEXCLUI	:= .t.
	Case nOpcX == 6
		_xCOPIA	:= .t.
	OtherWise
		_XVISUAL	:= .t.
	EndCase

	//--------------------------------------------------
	//Montando aHeader
	//---------------------------------------------------------------
	dbSelectArea("SX3")
	dbSetOrder(1)
	dbSeek(_TABPESQ)

	While !Eof() .And. (x3_arquivo == _TABPESQ)
		IF !X3USO(x3_usado)  //.or. Alltrim( SX3->X3_CAMPO ) $ 'ZL_GRUPO/ZL_DESCRIC'
			dbskip()
			loop
		end
		If alltrim(x3_campo)==_CHAVPESQ
			dbskip()
			loop
		end

		AADD(aHeader,{ TRIM(x3_titulo), alltrim(x3_campo), x3_picture,x3_tamanho, x3_decimal,".t.",x3_usado, x3_tipo, x3_arquivo, x3_context } )
		iF X3Obrigat(X3_CAMPO)
			Aadd(aObrigat,alltrim(X3_CAMPO))
		eND
		aADD(aGetsGD,AllTrim(x3_campo))
		dbSkip()
	End

	nUsado:=Len(aHeader)

	//--------------------------------------------------
	//Montando aCols
	//---------------------------------------------------------------

	IF _XVISUAL .or. _XALTERA .or. _XEXCLUI.or. _xCOPIA


		_CAMPO		:=_TABPESQ+"->"+_CHAVPESQ
		_CPOFIL		:=_TABPESQ+"->"+SubStr(_TABPESQ, 2, 2)+"_FILIAL"
		_CHAVPESQ1	:=&(_CAMPO)

		//campos do cabec
		CZ1TABELA	:=&(_CAMPO)
		U_f023gat()

		dbSelectarea(_TABPESQ)
		dbSetOrder(_ORDPESQ)
		dbGoTop()

		dbSeek( xFilial( _TABPESQ ) + _CHAVPESQ1, .f. )

		While !Eof()  .and. &(_CPOFIL)	== xFilial( _TABPESQ ) //.and. SZL->ZL_GRUPO	== cZLGrupo
			IF _CHAVPESQ1<>&(_CAMPO)
				dbSkip()
				Loop
			End

			Aadd(aDelRecno,(_TABPESQ)->(RECNO()))
			aAdd( aCols, Array( nUsado+1 ) )

			For _ni := 1 to nUsado
				if aHeader[_ni,10]<>'R' //context
					dbSelectArea('SX3')
					dbSetOrder(2)
					dbSeek(aHeader[ _ni, 2 ])
					aCols[ Len( aCols ), _ni ]	:= &(SX3->X3_INIBRW)
					dbSelectArea(_TABPESQ)
				else
					aCols[ Len( aCols ), _ni ]	:= &(  _TABPESQ+'->' + aHeader[ _ni, 2 ] )
				end
			Next

			aCols[ Len( aCols ), nUsado+1 ] := .f.
			dbSkip()
		End

	End

	IF _XINCLUI
		CZ1TABELA	:=criavar(_CHAVPESQ,.f.)
		CZ1DESC		:=CRIAVAR('DA0_DESCRI',.F.)

		Aadd(aCols,Array(nUsado+1))
		For _ni := 1 to nUsado
			aCols[Len( aCols ),_ni]:=CRIAVAR(aHeader[_ni,2])
		next

		aCols[ Len( aCols ), nUsado+1 ] := .f.
	End

	//--------------------------------------------------
	//Variaveis do Rodape do Modelo 2
	//---------------------------------------------------------------
	nLinGetD:=0
	//--------------------------------------------------
	//Array com descricao dos campos do Cabecalho do Modelo 2
	//---------------------------------------------------------------
	aC:={}
	// aC[n,1] = Nome da Variavel Ex.:"cCliente"
	// aC[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
	// aC[n,3] = Titulo do Campo
	// aC[n,4] = Picture
	// aC[n,5] = Validacao
	// aC[n,6] = F3
	// aC[n,7] = Se campo e' editavel .t. se nao .f.

	AADD(aCabec,{"cZ1Tabela" 			,{15,010} ,"Tabela"  	   	,"@!"  		,"U_f023gat()","DA0"		,_XINCLUI})
	AADD(aCabec,{"cZ1Desc"				,{30,010} ,"Descrição"  	,"@S100 "	,		      ,""   		,.F.	   })

	//--------------------------------------------------
	//Array com descricao dos campos do Rodape do Modelo 2
	//---------------------------------------------------------------
	aRodap:={}
	// aRodap[n,1] = Nome da Variavel Ex.:"cCliente"
	// aRodap[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
	// aRodap[n,3] = Titulo do Campo
	// aRodap[n,4] = Picture
	// aRodap[n,5] = Validacao
	// aRodap[n,6] = F3
	// aRodap[n,7] = Se campo e' editavel .t. se nao .f.
	//--------------------------------------------------
	//Array com coordenadas da GetDados no modelo2
	//---------------------------------------------------------------
	aCGD:={075,095,010,450}

	//--------------------------------------------------
	//Validacoes na GetDados da Modelo 2
	//---------------------------------------------------------------

	cLineOk		:='AllwaysTrue()'
	cAllOk 		:='u_fAllOk()'
	//aGetsGD	:={'ZL_GRUPO','ZL_DESCRIC','ZL_VLRPREV','ZL_VLRREAL','ZL_VLRREP','ZL_VARIAVE','ZL_ATIVO','ZL_VIGENCI','ZL_DSVAR','ZL_TIPO'}
	bF4			:=""
	cIniCpos	:=""
	nMax		:=999
	aCordW 		:= MsAdvSize( NIL , .F. )
	lMaximized 	:= .T.
	lDelGetD	:=.t.
	aButtons	:={}

	// lRetMod2 = .t. se confirmou, .f. se cancelou
	lRetMod2:=Modelo2(_TITULO,aCabec,aRodap,aCGD,nOpcx,cLineOk,cAllOk,aGetsGD,bF4,cIniCpos,nMax,aCordW,lDelGetD,lMaximized, aButtons)

	If lRetMod2
		fDataSave()
	End
Return
//---------------------------------------------------------------------------------------------
User Function f023gat()
//---------------------------------------------------------------------------------------------
	Local aArea:=GetArea()
	If Empty(cZ1Tabela)
		MsgInfo('Tabela Não Informada', 'Erro')
		Return .f.
	End
	cZ1Desc:=''

	IF _XINCLUI
		If !existCpo('DA0',cZ1Tabela)
			//MsgInfo('Tabela Não Encontrada', 'Tabela Não EnContrada')
			RestArea(aarea)
			Return .f.
		End
		DbSelectArea('SZ1')
		DbSetOrder(1)
		If dbSeek(xFilial('SZ1')+cZ1Tabela)
			MsgInfo('Tabela JA Cadastrada', 'Tabela JA Cadastrada')
			cZ1Tabela:='  '
			RestArea(aarea)

			Return .f.
		End
	end
	IF !_XINCLUI
		cZ1Desc:=posicione('DA0',1,xFilial('DA0')+cZ1Tabela,'DA0_DESCRI')
	end
	RestArea(aarea)

Return .t.

//---------------------------------------------------------------------------------------------
User Function fAllOk()
//---------------------------------------------------------------------------------------------

	Local lReturn	:= .t.,nH
	Local n
	Local nItens	:= 0

	IF _XEXCLUI
		return .t.
	End


	IF EMPTY(cZ1Tabela)
		MSGALERT('Campos Grupo ou Descrição Não Foram Preenchidos','Verificar Campos')
		Return .f.
	END


	For n := 1 to Len( aCols )

		If aCols[ n, Len( aHeader ) + 1 ]
			LOOP
		END

		nItens ++

		For nH:=1 to Len(aHeader)
			If ascan(aObrigat, aCols[ n, nH ])<> 0 .and.;
					Empty( aCols[ n, nH ] )

				MSGALERT('Campo '+aHeader[nH,1]+' é obrigatorio e não foi preenchido','Verificar Campos')
				lReturn := .f.
				Exit
			EndIf

		next

	Next

	If lReturn .and. nItens == 0
		MSGALERT('Campos Obrigatorios Não Foram Preenchidos','Verificar Campos')
		lReturn := .f.
	End

Return( lReturn )

//-------------------------------------------------------------------------------------------
Static Function fDataSave()
	//-----------------------------------------------------------------------------------------
	Local nK,nC,nX
	If _XEXCLUI.or. _XALTERA

		dbSelectarea(_TABPESQ)

		FOR nK:=1 to Len(aDelRecno)
			dbGoTo(aDelRecno[nK])

			RecLock( _TABPESQ, .f. )
			dbDelete()
			MsUnlock()

		End
	end

	If _XINCLUI .or. _XALTERA.or. _xCOPIA
		dbSelectArea(_TABPESQ)

		For nX:=1 to Len(aCols)
			iF aCols[nX,nUsado+1]
				loop
			end

			RecLock( _TABPESQ, .t. )

			_CAMPO		:=_TABPESQ+"->"+_CHAVPESQ
			&(_CAMPO)	:=cZ1Tabela

			_CPOFIL		:=_TABPESQ+"->"+SubStr(_TABPESQ, 2, 2)+"_FILIAL"
			&(_CPOFIL)	:=xFilial( _TABPESQ )

			For nC := 1 to nUsado
				cCampo:=_TABPESQ + '->'+aHeader[ nC, 2 ]
				&(cCampo):=aCols[nX,nC]
			Next
			msUnlock()
		NEXT
	end
Return
