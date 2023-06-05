#include "rwmake.ch"
#Include "Totvs.ch"
#Include "TopConn.ch"
#include "protheus.ch"
#include "tbiconn.ch"
#include "rwmake.ch"
#INCLUDE "FILEIO.CH"
#include "colors.ch"
#include "sigawin.ch"
#include "dbtree.ch"

User Function IMPETQ(_xFilial, _xOrdem)
	Local _aArea   := GetArea()
	Local _cFilial := _xFilial
	Local _cOrdem  := _xOrdem
	Local _nx	   := 1
	_lRet := .F.

	_nEtiq := 0
	_nEtiqA:= 0
	DbSelectArea("CB7")
	DbSeek(_cFilial+_cOrdem)
	If Found()
		_cCliente := CB7->CB7_CLIENT
		_cLojaCli := CB7->CB7_LOJA

		DBSelectArea("CB8")
		DbSeek(_cFilial+_cOrdem)
		Do While !CB8->(EOF()) .And. _cFilial+_cOrdem == CB8->CB8_FILIAL+CB8->CB8_ORDSEP
			_cPedido  := CB8->CB8_PEDIDO
			If !Empty(CB8->CB8_PROD)
				DbSelectArea("SB1")
				DbSeek(xFilial("SB1")+CB8->CB8_PROD)
				If Found()
					_nEtiq += Round(CB8->CB8_QTDORI/SB1->B1_CONV,0)
				EndIf
			EndIf
			CB8->(DbSkip())
		EndDo

		If MsgBox("Confirme a impressao de "+Alltrim(STR(_nEtiq))+" volume?","ATENCAO","YESNO")
			_nEtiqA := 0
			_lRet := .T.
			CB5SetImp("000001")
			MSCBCHKSTATUS(.F.)
			For _nx:=1 To _nEtiq
				_nEtiqA += 1
				MSCBBEGIN(1,6)
				DbSelectArea("SA1")
				DbSetOrder(1)
				DbSeek(xFilial("SA1")+_cCliente+_cLojaCli)
				If Found()
					x:= RAt('_', STRTRAN(Left(Alltrim(SA1->A1_NOME),22)," ","_"))
					_End := 'CEP: '+Transform(Alltrim(SA1->A1_CEP), "@R 99.999-999")+' - '+Alltrim(SA1->A1_MUN)+' - '+Alltrim(SA1->A1_EST)
					MSCBSAY(04,03,Substring(Alltrim(SA1->A1_NOME),00,x-1),'N','0','70',.F.,.F.,Nil,Nil,Nil)
					MSCBSAY(04,12,Substring(Alltrim(SA1->A1_NOME),x+1,50),'N','0','70',.F.,.F.,Nil,Nil,Nil)
					MSCBSAY(04,21,PADC(_End,43),'N','0','30',.F.,.F.,Nil,Nil,Nil)
				EndIf
				MSCBSAY(04,30,'PEDIDO: '+_cPedido,'N','0','77',.F.,.F.,Nil,Nil,Nil)
				MSCBSAY(04,40,'VOLUME: '+Alltrim(STR(_nEtiqA))+"/"+Alltrim(STR(_nEtiq)),'N','0','77',.F.,.F.,Nil,Nil,Nil)

				MSCBSAY(04,70,Alltrim(UsrFullName(__cUserID))+"  "+dToc(dDataBase)+"  "+Left(Time(),5),'N','0','20',.F.,.F.,Nil,Nil,Nil)
				MSCBEND()
			Next
			MSCBEND()
		Else
			_nCaixas := Val(FWInputBox("Informe a quantidade de volume", "1"))
			If MsgBox("Confirme a impressao de "+Alltrim(STR(_nCaixas))+" volume?","ATENCAO","YESNO")
				_nEtiqA := 0
				_lRet := .T.
				CB5SetImp("000001")
				MSCBCHKSTATUS(.F.)
				For _nx:=1 To _nCaixas
					_nEtiqA += 1
					MSCBBEGIN(1,6)
					DbSelectArea("SA1")
					DbSetOrder(1)
					DbSeek(xFilial("SA1")+_cCliente+_cLojaCli)
					If Found()
						x:= RAt('_', STRTRAN(Left(Alltrim(SA1->A1_NOME),22)," ","_"))
						_End := 'CEP: '+Transform(Alltrim(SA1->A1_CEP), "@R 99.999-999")+' - '+Alltrim(SA1->A1_MUN)+' - '+Alltrim(SA1->A1_EST)
						MSCBSAY(04,03,Substring(Alltrim(SA1->A1_NOME),00,x-1),'N','0','70',.F.,.F.,Nil,Nil,Nil)
						MSCBSAY(04,12,Substring(Alltrim(SA1->A1_NOME),x+1,50),'N','0','70',.F.,.F.,Nil,Nil,Nil)
						MSCBSAY(04,21,PADC(_End,43),'N','0','30',.F.,.F.,Nil,Nil,Nil)
					EndIf
					MSCBSAY(04,30,'PEDIDO: '+_cPedido,'N','0','77',.F.,.F.,Nil,Nil,Nil)
					MSCBSAY(04,40,'VOLUME: '+Alltrim(STR(_nEtiqA))+"/"+Alltrim(STR(_nCaixas)),'N','0','77',.F.,.F.,Nil,Nil,Nil)

					MSCBSAY(04,70,Alltrim(UsrFullName(__cUserID))+"  "+dToc(dDataBase)+"  "+Left(Time(),5),'N','0','20',.F.,.F.,Nil,Nil,Nil)
					MSCBEND()
				Next
				MSCBEND()
			EndIf
			_nPall := Val(FWInputBox("Informe a quantidade de Pallet", "1"))
			If MsgBox("Confirme a impressao de "+Alltrim(STR(_nPall))+" Pallet ?","ATENCAO","YESNO")
				_nEtiqA := 0
				_lRet := .T.
				CB5SetImp("000001")
				MSCBCHKSTATUS(.F.)
				For _nx:=1 To _nPall
					_nEtiqA += 1
					MSCBBEGIN(1,6)
					DbSelectArea("SA1")
					DbSetOrder(1)
					DbSeek(xFilial("SA1")+_cCliente+_cLojaCli)
					If Found()
						x:= RAt('_', STRTRAN(Left(Alltrim(SA1->A1_NOME),22)," ","_"))
						_End := 'CEP: '+Transform(Alltrim(SA1->A1_CEP), "@R 99.999-999")+' - '+Alltrim(SA1->A1_MUN)+' - '+Alltrim(SA1->A1_EST)
						MSCBSAY(04,03,Substring(Alltrim(SA1->A1_NOME),00,x-1),'N','0','70',.F.,.F.,Nil,Nil,Nil)
						MSCBSAY(04,12,Substring(Alltrim(SA1->A1_NOME),x+1,50),'N','0','70',.F.,.F.,Nil,Nil,Nil)
						MSCBSAY(04,21,PADC(_End,43),'N','0','30',.F.,.F.,Nil,Nil,Nil)
					EndIf
					MSCBSAY(04,30,'PEDIDO: '+_cPedido,'N','0','77',.F.,.F.,Nil,Nil,Nil)
					MSCBSAY(04,40,'PALLET:  '+Alltrim(STR(_nEtiqA))+"/"+Alltrim(STR(_nPall)),'N','0','77',.F.,.F.,Nil,Nil,Nil)

					MSCBSAY(04,70,Alltrim(UsrFullName(__cUserID))+"  "+dToc(dDataBase)+"  "+Left(Time(),5),'N','0','20',.F.,.F.,Nil,Nil,Nil)
					MSCBEND()
				Next
				MSCBEND()
			EndIf
		EndIf
	EndIf
	RestArea(_aArea)
Return()
