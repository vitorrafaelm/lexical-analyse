%{
/* ==========================================================================
 * owl_lexer.l - Regras do Analisador Léxico para OWL2 Manchester Syntax
 *
 * Este arquivo contém as regras Flex de reconhecimento de padrões.
 * ========================================================================== */

#include "token.h"
#include "symbol_table.h"
#include <stdio.h>

/* Contador de linhas (visível para main.c) */
int line_num = 1;

/* Registra um token na tabela e imprime na saída */
static void emit(TokenType type, const char *lexeme) {
    printf("  %-5d  %-22s  %s\n", line_num, token_type_name(type), lexeme);
    symtable_insert(type, lexeme, line_num);
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
"Class:"            { emit(TOK_CLASS, yytext); }
"EquivalentTo:"     { emit(TOK_EQUIVALENT_TO, yytext); }
"Individuals:"      { emit(TOK_INDIVIDUALS, yytext); }
"SubClassOf:"       { emit(TOK_SUBCLASS_OF, yytext); }
"DisjointClasses:"  { emit(TOK_DISJOINT_CLASSES, yytext); }

 /* ===== Palavras reservadas                                 ===== */
 /* ===== Ex: some, all, value, min, max, exactly, that, etc. ===== */
"some"      { emit(TOK_SOME, yytext); }
"all"       { emit(TOK_ALL, yytext); }
"only"      { emit(TOK_ONLY, yytext); }
"value"     { emit(TOK_VALUE, yytext); }
"min"       { emit(TOK_MIN, yytext); }
"max"       { emit(TOK_MAX, yytext); }
"exactly"   { emit(TOK_EXACTLY, yytext); }
"that"      { emit(TOK_THAT, yytext); }
"not"       { emit(TOK_NOT, yytext); }
"and"       { emit(TOK_AND, yytext); }
"or"        { emit(TOK_OR, yytext); }

 /* ===== Namespace IDs (xsd:, owl:, rdfs:, rdf:)             ===== */
"xsd:"      { emit(TOK_NAMESPACE_ID, yytext); BEGIN(DATATYPE); }
"owl:"      { emit(TOK_NAMESPACE_ID, yytext); BEGIN(DATATYPE); }
"rdfs:"     { emit(TOK_NAMESPACE_ID, yytext); BEGIN(DATATYPE); }
"rdf:"      { emit(TOK_NAMESPACE_ID, yytext); BEGIN(DATATYPE); }

 /* ===== Estado DATATYPE: reconhece o tipo após namespace    ===== */
<DATATYPE>[ \t]+        { /* ignora espaços no estado DATATYPE */ }
<DATATYPE>[a-zA-Z]+     { emit(TOK_DATA_TYPE, yytext); BEGIN(INITIAL); }

 /* ===== Símbolos especiais                                  ===== */
">="    { emit(TOK_GTE, yytext); }
"<="    { emit(TOK_LTE, yytext); }
"["     { emit(TOK_LBRACKET, yytext); }
"]"     { emit(TOK_RBRACKET, yytext); }
"{"     { emit(TOK_LBRACE, yytext); }
"}"     { emit(TOK_RBRACE, yytext); }
"("     { emit(TOK_LPAREN, yytext); }
")"     { emit(TOK_RPAREN, yytext); }
">"     { emit(TOK_GT, yytext); }
"<"     { emit(TOK_LT, yytext); }
"\""    { emit(TOK_QUOTE, yytext); }
","     { emit(TOK_COMMA, yytext); }

 /* ===== Nomes de indivíduos                                 ===== */
 /* ===== Ex: Customer1, Waiter2, AmericanaHotPizza1          ===== */
[A-Z][a-zA-Z]*[0-9]+   { emit(TOK_INDIVIDUAL_ID, yytext); }

 /* ===== Identificadores de classes                          ===== */
 /* ===== Ex: Pizza, VegetarianPizza, OWL2Class               ===== */
[A-Z][a-zA-Z_0-9]*     { emit(TOK_CLASS_ID, yytext); }

 /* ===== Identificadores de propriedades                     ===== */
 /* ===== Ex: hasTopping, isBaseOf, ssn, purchasedPizza        ===== */
[a-z][a-zA-Z]*          { emit(TOK_PROPERTY_ID, yytext); }

 /* ===== Números inteiros (cardinalidades)                   ===== */
[0-9]+                  { emit(TOK_INTEGER, yytext); }

 /* ===== Erro léxico: caractere não reconhecido              ===== */
.       { emit(TOK_ERROR, yytext); }

%%
