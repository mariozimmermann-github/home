User Function ACD100M()
//aRotina := {}

aadd(aRotina,{'Impressao de Etiquetas', 'U_IMPETQ(CB7->CB7_FILIAL, CB7->CB7_ORDSEP)', 0, 1, 0, NIL})
aadd(aRotina,{'Impressao da Ordem', 'U_SEPARA()', 0, 1, 0, NIL})

Return(aRotina)

