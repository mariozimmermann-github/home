#Include "Totvs.ch"
#Include "RptDef.CH"
#include "PROTHEUS.CH"
#INCLUDE 'TBICONN.CH'
#INCLUDE "TCBROWSE.CH"
#include "rwmake.CH"
#include "ap5mail.ch"
#INCLUDE "FWPrintSetup.ch"
#Include "TopConn.Ch"
/*
+-----------+-----------+-------+-------------------------------------+------+----------+
| Funcao    | UNIXFUN   | Autor | Manoel M Mariante                   | Data |11/2021   |
|-----------+-----------+-------+-------------------------------------+------+----------|
| Descricao | ajuste da base de comissao retirando o valor do frete dos titulos gerados |
|           |                                                                           |
|           |                                                                           |
|-----------+---------------------------------------------------------------------------|
| Sintaxe   | executado via menu                                                        |
+-----------+---------------------------------------------------------------------------+
*/

//-------------------------------------------------------------------------------
User Function UNIPUTSX1( cX1_GRUPO, cX1_ORDEM,cX1_PERGUNT, cX1_VAR01,  cX1_TIPO, cX1_TAMANHO,cX1_DECIMAL,cX1_GSC,cX1_VALID,cX1_DEF01, cX1_DEF02,cX1_DEF03,cX1_DEF04, cX1_DEF05, cX1_VARIAVL,cX1_F3)
	//-------------------------------------------------------------------------------
	cX1_GRUPO:=PADR(Alltrim(cX1_GRUPO),10,' ')
	dbSelectArea("SX1")
	dbSetOrder(1)
	If !dbSeek(cX1_GRUPO+cX1_ORDEM)
		Reclock("SX1",.t.)
	Else
		IF	X1_GRUPO	<> cX1_GRUPO.or.;
			X1_ORDEM	<> cX1_ORDEM.or.;
			X1_PERGUNT	<> cX1_PERGUNT.or.;
			X1_VARIAVL	<> cX1_VARIAVL.or.;
			X1_TIPO		<> cX1_TIPO.or.;
			X1_TAMANHO	<> cX1_TAMANHO.or.;
			X1_DECIMAL	<> cX1_DECIMAL.or.;
			X1_GSC		<> cX1_GSC.or.;
			X1_VALID	<> cX1_VALID.or.;
			X1_DEF01	<> cX1_DEF01.or.;
			X1_DEF02	<> cX1_DEF02.or.;
			X1_DEF03	<> cX1_DEF03.or.;
			X1_DEF04	<> cX1_DEF04.or.;
			X1_DEF05	<> cX1_DEF05.or.;
			X1_VAR01	<> cX1_VAR01.or.;
			X1_F3   	<> cX1_F3
			Reclock("SX1",.F.)
		End
	end
	X1_GRUPO	:=cX1_GRUPO
	X1_ORDEM	:=cX1_ORDEM
	X1_PERGUNT	:=cX1_PERGUNT
	X1_VARIAVL	:=cX1_VARIAVL
	X1_TIPO		:=cX1_TIPO
	X1_TAMANHO	:=cX1_TAMANHO
	X1_DECIMAL	:=cX1_DECIMAL
	X1_GSC		:=cX1_GSC
	X1_VALID	:=cX1_VALID
	X1_DEF01	:=cX1_DEF01
	X1_DEF02	:=cX1_DEF02
	X1_DEF03	:=cX1_DEF03
	X1_DEF04	:=cX1_DEF04
	X1_DEF05	:=cX1_DEF05
	X1_VAR01	:=cX1_VAR01
	X1_F3   	:=cX1_F3
	msUnlock()

Return

User Function FSitWMS(cCodSit)
	Local cDesc:='NÃO CADASTRADA'
	IF cCodSit=='00'    ; cDesc:='Não Liberado para Coleta'
	elseif cCodSit=='05'; cDesc:='Liberado Mas Não Integrado
	elseif cCodSit=='10'; cDesc:='Integrado
	elseif cCodSit=='20'; cDesc:='Separação Iniciada
	elseif cCodSit=='30'; cDesc:='Separação Finalizada
	elseif cCodSit=='33'; cDesc:='Falta de Estoque
	elseif cCodSit=='40'; cDesc:='Faturamento Autorizado
	elseif cCodSit=='50'; cDesc:='Mercadoria Enviada'
	end


Return cDesc
