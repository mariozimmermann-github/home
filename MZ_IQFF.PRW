// Programa...: MZ_IQFF
// Autor......: Maxim Solucoes Empresariais
// Data.......: 02/03/2011
// Cliente....: Clientes Maxim
// Descricao..: Listagem dos IQF por fornecedor x mes (periodo 6 meses)
//

#Include "rwmake.CH"
#include "topconn.ch"

User Function MZ_IQFF()
Local titulo  := "Analise IQF - Por Fornecedor "
Local cString := "QEV"
Local wnrel   := "MZ_IQFF"
Local cDesc1  := " Este programa ira imprimir a Rela豫o dos IQF por fornecedor."
Local cDesc2  := " "
Local cDesc3  := " "
Local tamanho := "G"

Private aReturn  := {"Zebrado",1,"Administracao", 1, 2, 1, "",1 }
Private cPerg    :=PADR("MZ_IQFF",LEN(SX1->X1_GRUPO)," ")
Private nLastKey := 0


//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//� Verifica as perguntas selecionadas                           �
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
_ValidPerg ()
Pergunte(cperg,.F.)

wnrel:=SetPrint(cString,wnrel,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.F.,,.F.,Tamanho)

SetDefault(aReturn,cString)

If nLastKey = 27
	Return
Endif

RptStatus({|lEnd| Continua(@lEnd,wnRel,titulo,tamanho)},titulo)

Return NIL

Static Function Continua(lEnd,wnRel,titulo,tamanho)
Local CbCont,cabec1,cabec2,cbtxt
Local limite   :=120
Local nomeprog :="MZ_IQFF"
Private nLin   := 80
Private M_PAG  := 1      
Private nQtMesAcu := 6
Private aAnoMes   := {}
//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//� Monta os Cabecalhos                                          �
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
cabec1 := "FORNECEDOR                                         "
cabec2 := ""
//         12345 1234567890123456789012345678901234 1234567890123 1234567890123 123456789012
//                   1         2         3         4         5         6         7         8         9        10        11        12        13        14        15        16        17        18        19        20        21        22
//         01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890

cAnoIni    := Str(mv_par01,4)
cAnoFim	   := Str(mv_par01,4)
cMesIni    := StrZero(mv_par02,2)
cMesFim	   := StrZero(mv_par02,2)
_nCol      := 50
aadd(aAnoMes, { cAnoFim, StrZero(Val(cMesFim),2), _nCol, 0, 0})
cabec1     += "  "+StrZero(Val(cMesFim),2)+"/"+cAnoFim+" "
nCtAM      := 1
Do While .T.
	cMesIni := StrZero(Val(cMesIni)-1,2)
	If cMesIni == "00"
		cAnoIni := StrZero(Val(cAnoIni)-1,4)
		cMesIni := "12"
	EndIf
	_nCol+=10
	aadd(aAnoMes, { cAnoIni, StrZero(Val(cMesIni),2),_nCol , 0, 0})	
	cabec1 += "  "+cMesIni+"/"+cAnoIni+" "
	nCtAM++                                               

	If (nCtAM == 6 .And. mv_par03 == 1) .Or. (nCtAM == 8 .And. mv_par03 == 2)
		Exit
	EndIf
EndDo
cabec1 += "TOTAL/MEDIA"
aAnoMes := asort(aAnoMes,,,{|x,y| x[1]+x[2] < y[1]+y[2]})

_cCompAnt := ""
_nQtProd  := 0
_nQtCons  := 0
_aOps     := {}
_aProd    := {}
dbSelectarea("SD3")
DbSetOrder(1)
_sQuery := ""
_sQuery += " SELECT QEV_FORNEC,QEV_ANO,QEV_MES, AVG(QEV_IQF) AS QEV_IQF FROM " + RetSqlName("QEV")+" QEV "
_sQuery += " WHERE QEV.QEV_FILIAL = '" + xFilial("QEV") + "' "
_sQuery += " AND QEV.QEV_LOTENT  > 0 "
_sQuery += " AND QEV.QEV_ANO+QEV.QEV_MES >= '"+(cAnoIni+cMesIni)+"' "
_sQuery += " AND QEV.QEV_ANO+QEV.QEV_MES <= '"+(cAnoFim+cMesFim)+"' "     
_sQuery += " AND QEV_FORNEC >= '"+MV_PAR04+"' "
_sQuery += " AND QEV_FORNEC <= '"+MV_PAR05+"' "
_sQuery += " GROUP BY QEV_FORNEC,QEV_ANO,QEV_MES "
_sQuery += " ORDER BY QEV.QEV_FORNEC, QEV.QEV_ANO+QEV.QEV_MES DESC"
tcquery _sQuery new alias _TRB1
_cForAnt    := ""     
_nIqfFor    := 0 
_nQtIqfFor	:= 0 
SetRegua(_TRB1->(LastRec()))
DbGoTop()
While !_TRB1->(Eof() )
	
	If lEnd
		@Prow()+1,001 PSay "CANCELADO PELO OPERADOR"
		Exit
	EndIF	
	IncRegua()
	If nLin > 58
		cabec(titulo,cabec1,cabec2,nomeprog,tamanho,15)
		nLin  := 8
	EndIf
	
	If _cForAnt <> _TRB1->QEV_FORNEC                                                                            
		IF !Empty(_cForAnt) 
			If _nIqfFor <> 0 .And. _nQtIqfFor <> 0
				@ nLin,_nCol+13 PSay _nIqfFor/_nQtIqfFor Picture "@E 999.99"		
			Else                                                            
				@ nLin,_nCol+13 PSay 0 Picture "@E 999.99"					
			EndIf
			nLin  += 1		
		Endif
		If nLin > 58
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,15)
			nLin  := 8
		EndIf			
		@ nLin,000 PSay Left(_TRB1->QEV_FORNEC+"-"+fBuscaCpo("SA2",1,xFilial("SA2")+_TRB1->QEV_FORNEC,"SA2->A2_NOME"),39)
		_nIqfFor    := 0 
		_nQtIqfFor	:= 0 
	Endif
	_nPosCol    := aScan(aAnoMes, {|x| x[1]+x[2] ==_TRB1->QEV_ANO+_TRB1->QEV_MES })	
	If _nPosCol > 0
		@ nLin,aAnoMes[_nPosCol,3]+3 PSay _TRB1->QEV_IQF Picture "@E 999.99"
		If _TRB1->QEV_IQF <> 0
			_nIqfFor   += _TRB1->QEV_IQF
			_nQtIqfFor += 1
			
			aAnoMes[_nPosCol, 4] += _TRB1->QEV_IQF
			aAnoMes[_nPosCol, 5] += 1			
		Endif
	Endif
	_cForAnt := _TRB1->QEV_FORNEC     			
	DbSelectArea("_TRB1")
	_TRB1->(DbSkip())
EndDo   
If Len(aAnoMes) > 0
	nLin  += 2
	If nLin > 58
		cabec(titulo,cabec1,cabec2,nomeprog,tamanho,15)
		nLin  := 8
	EndIf	   
	_nIqfFor    := 0 
	_nQtIqfFor	:= 0 		
	@ nLin,000 PSay " TOTAL GERAL" 
	For xx := 1 to Len(aAnoMes)            
		If aAnoMes[xx,4]<> 0 .And. aAnoMes[_nPosCol,5] <> 0
			@ nLin,aAnoMes[xx,3]+3 PSay  aAnoMes[xx,4]/aAnoMes[xx,5] Picture "@E 999.99"
			_nIqfFor   += aAnoMes[xx,4]/aAnoMes[xx,5]
			_nQtIqfFor += 1			
		Else                                                                                              
			@ nLin,aAnoMes[xx,3]+3 PSay  0 Picture "@E 999.99"		
		Endif
	Next   
	If _nIqfFor <> 0 .And. _nQtIqfFor <> 0
		@ nLin,_nCol+13 PSay _nIqfFor/_nQtIqfFor Picture "@E 9999.99"		
	Else                                                            
		@ nLin,_nCol+13 PSay 0 Picture "@E 9999.99"					
	EndIf	
Endif
DbSelectArea("_TRB1")
_TRB1->(DbCloseArea())
DbSelectArea("SB1")

If aReturn[5] = 1
	Set Printer To
	dbCommitall()
	ourspool(wnrel)
Endif

MS_FLUSH()

Return NIL

// --------------------------------------------------------------------------
// Cria perguntas no SX1. Se a pergunta ja existir, atualiza. Se houver mais
// perguntas no SX1 do que as definidas aqui, deleta as excedentes do SX1.
Static Function _ValidPerg ()
local _aArea  := GetArea ()
local _aRegs  := {}
local _aHelps := {}
local _i      := 0
local _j      := 0

_aRegs = {}
//           GRUPO  ORDEM PERGUNT                           PERSPA PERENG VARIAVL   TIPO TAM DEC PRESEL GSC  VALID VAR01       DEF01     DEFSPA1 DEFENG1 CNT01 VAR02 DEF02        DEFSPA2 DEFENG2 CNT02 VAR03 DEF03    DEFSPA3 DEFENG3 CNT03 VAR04 DEF04 DEFSPA4 DEFENG4 CNT04 VAR05 DEF05 DEFSPA5 DEFENG5 CNT05 F3     GRPSXG
AADD(_aRegs,{cPerg, "01", "Ano Base   ?", "",    "",    "mv_ch1", "N", 04, 0,  0,     "G", "",   "mv_par01", "",       "",     "",     "",   "",   "",          "",     "",     "",   "",   "",      "",     "",     "",   "",   "",   "",     "",     "",   "",   "",   "",     "",     "",   "", ""})
AADD(_aRegs,{cPerg, "02", "Mes Base   ?", "",    "",    "mv_ch2", "N", 02, 0,  0,     "G", "",   "mv_par02", "",       "",     "",     "",   "",   "",          "",     "",     "",   "",   "",      "",     "",     "",   "",   "",   "",     "",     "",   "",   "",   "",     "",     "",   "", ""})
AADD(_aRegs,{cPerg, "03", "Qtde Meses ?", "",    "",    "mv_ch3", "N", 01, 0,  0,     "C", "",   "mv_par03","6 Meses","","","","","8 Meses","","","","","","","","","","","","","","","","","","","",""})
AADD(_aRegs,{cPerg, "04", "Fornecedor De ?", "",    "", "mv_ch4", "C", 06, 0,  0,     "G", "",   "mv_par04", "",       "",     "",     "",   "",   "",          "",     "",     "",   "",   "",      "",     "",     "",   "",   "",   "",     "",     "",   "",   "",   "",     "",     "",   "SA2", ""})
AADD(_aRegs,{cPerg, "05", "Fornecedor Ate ?", "",    "","mv_ch5", "C", 06, 0,  0,     "G", "",   "mv_par05", "",       "",     "",     "",   "",   "",          "",     "",     "",   "",   "",      "",     "",     "",   "",   "",   "",     "",     "",   "",   "",   "",     "",     "",   "SA2", ""})
// Definicao de textos de help (versao 7.10 em diante): uma array para cada linha.
_aHelps = {}
//              Ordem   1234567890123456789012345678901234567890    1234567890123456789012345678901234567890    1234567890123456789012345678901234567890
//aadd (_aHelps, {"01", {"Informe o texto do help aqui (linha 1)  ", ""Informe o texto do help aqui (linha 2) ", ""Informe o texto do help aqui (linha 3) "}})  // ... pode-se criar mais linhas, se necessario.
//aadd (_aHelps, {"02", {"Informe o texto do help aqui (linha 1)  ", ""Informe o texto do help aqui (linha 2) ", ""Informe o texto do help aqui (linha 3) "}})  // ... pode-se criar mais linhas, se necessario.
// ...

DbSelectArea ("SX1")
DbSetOrder (1)
For _i := 1 to Len (_aRegs)
	If ! DbSeek (cPerg + _aRegs [_i, 2])
		RecLock("SX1", .T.)
	else
		RecLock("SX1", .F.)
	endif
	For _j := 1 to FCount ()
		
		// Campos CNT nao sao gravados para preservar conteudo anterior.
		If _j <= Len (_aRegs [_i]) .and. left (fieldname (_j), 6) != "X1_CNT" .and. fieldname (_j) != "X1_PRESEL"
			FieldPut (_j, _aRegs [_i, _j])
		Endif
	Next
	MsUnlock()
	
Next

// Deleta do SX1 as perguntas que nao constam em _aRegs
DbSeek (cPerg, .T.)
do while ! eof () .and. x1_grupo == cPerg
	if ascan (_aRegs, {|_aVal| _aVal [2] == sx1 -> x1_ordem}) == 0
		RecLock("SX1", .F.)
		dbdelete ()
		MsUnlock()
	endif
	dbskip ()
enddo

// Gera helps das perguntas
For _i := 1 to Len (_aHelps)
	PutSX1Help ("P." + cPerg + _aHelps [_i, 1] + ".", _aHelps [_i, 2], {}, {})
next

restarea (_aArea)
Return
