%{
/* ==========================================================================
 * owl_lexer.l - Analisador Léxico integrado com Bison (Análise Sintática)
 *
 * Retorna tokens para o parser via return.
 * Preenche a tabela de símbolos como efeito colateral.
 * ========================================================================== */

#include "owl_parser.tab.h"
#include "symbol_table.h"
#include <string.h>
#include <stdio.h>

/* Contador de linhas (acessível pelo parser via extern) */
int line_num = 1;

/* Copia o lexema para yylval e insere na tabela de símbolos */
static int emit(int token) {
    strncpy(yylval.str, yytext, 255);
    yylval.str[255] = '\0';
    symtable_insert(token, yytext, line_num);
    return token;
}
%}

/* Desabilita a função yywrap (não lê múltiplos arquivos) */
%option noyywrap
%option nounput
%option noinput

/* Estado exclusivo para reconhecer tipos de dados após um namespace */
%x DATATYPE

%%
 /* ===== Espaços em branco e novas linhas                    ===== */
[ \t]+          { /* ignora espaços e tabulações */ }
\n              { line_num++; }

 /* ===== Palavras-chave OWL (seguidas de ':')                ===== */
 /* ===== Ex: Class: , EquivalentTo: , SubClassOf:            ===== */
"Class:"            { return emit(TOK_CLASS); }
"EquivalentTo:"     { return emit(TOK_EQUIVALENT_TO); }
"Individuals:"      { return emit(TOK_INDIVIDUALS); }
"SubClassOf:"       { return emit(TOK_SUBCLASS_OF); }
"DisjointClasses:"  { return emit(TOK_DISJOINT_CLASSES); }

 /* ===== Palavras reservadas                                 ===== */
 /* ===== Ex: some, all, value, min, max, exactly, that, etc. ===== */
"some"      { return emit(TOK_SOME); }
"all"       { return emit(TOK_ALL); }
"only"      { return emit(TOK_ONLY); }
"value"     { return emit(TOK_VALUE); }
"min"       { return emit(TOK_MIN); }
"max"       { return emit(TOK_MAX); }
"exactly"   { return emit(TOK_EXACTLY); }
"that"      { return emit(TOK_THAT); }
"not"       { return emit(TOK_NOT); }
"and"       { return emit(TOK_AND); }
"or"        { return emit(TOK_OR); }

 /* ===== Namespace IDs (xsd:, owl:, rdfs:, rdf:)             ===== */
"xsd:"      { BEGIN(DATATYPE); return emit(TOK_NAMESPACE_ID); }
"owl:"      { BEGIN(DATATYPE); return emit(TOK_NAMESPACE_ID); }
"rdfs:"     { BEGIN(DATATYPE); return emit(TOK_NAMESPACE_ID); }
"rdf:"      { BEGIN(DATATYPE); return emit(TOK_NAMESPACE_ID); }

 /* ===== Estado DATATYPE: reconhece o tipo após namespace    ===== */
<DATATYPE>[ \t]+        { /* ignora espaços no estado DATATYPE */ }
<DATATYPE>[a-zA-Z]+     { BEGIN(INITIAL); return emit(TOK_DATA_TYPE); }

 /* ===== Símbolos especiais                                  ===== */
">="    { return emit(TOK_GTE); }
"<="    { return emit(TOK_LTE); }
"["     { return emit(TOK_LBRACKET); }
"]"     { return emit(TOK_RBRACKET); }
"{"     { return emit(TOK_LBRACE); }
"}"     { return emit(TOK_RBRACE); }
"("     { return emit(TOK_LPAREN); }
")"     { return emit(TOK_RPAREN); }
">"     { return emit(TOK_GT); }
"<"     { return emit(TOK_LT); }
"\""    { return emit(TOK_QUOTE); }
","     { return emit(TOK_COMMA); }

 /* ===== Nomes de indivíduos                                 ===== */
 /* ===== Ex: Customer1, Waiter2, AmericanaHotPizza1          ===== */
[A-Z][a-zA-Z]*[0-9]+   { return emit(TOK_INDIVIDUAL_ID); }

 /* ===== Identificadores de classes                          ===== */
 /* ===== Ex: Pizza, VegetarianPizza, OWL2Class               ===== */
[A-Z][a-zA-Z_0-9]*     { return emit(TOK_CLASS_ID); }

 /* ===== Identificadores de propriedades                     ===== */
 /* ===== Ex: hasTopping, isBaseOf, ssn, purchasedPizza        ===== */
[a-z][a-zA-Z]*          { return emit(TOK_PROPERTY_ID); }

 /* ===== Números inteiros (cardinalidades)                   ===== */
[0-9]+                  { return emit(TOK_INTEGER); }

 /* ===== Erro léxico: caractere não reconhecido              ===== */
.       { return emit(TOK_ERROR); }

%%
