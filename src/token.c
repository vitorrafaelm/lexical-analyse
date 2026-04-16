/* ==========================================================================
 * token.c - Implementação das funções de token
 * ========================================================================== */

#include "token.h"

/* Tabela de nomes legíveis para cada tipo de token */
static const char *TOKEN_NAMES[] = {
    [TOK_CLASS] = "CLASS",
    [TOK_EQUIVALENT_TO] = "EQUIVALENT_TO",
    [TOK_INDIVIDUALS] = "INDIVIDUALS",
    [TOK_SUBCLASS_OF] = "SUBCLASS_OF",
    [TOK_DISJOINT_CLASSES] = "DISJOINT_CLASSES",

    [TOK_SOME] = "SOME",
    [TOK_ALL] = "ALL",
    [TOK_ONLY] = "ONLY",
    [TOK_VALUE] = "VALUE",
    [TOK_MIN] = "MIN",
    [TOK_MAX] = "MAX",
    [TOK_EXACTLY] = "EXACTLY",
    [TOK_THAT] = "THAT",
    [TOK_NOT] = "NOT",
    [TOK_AND] = "AND",
    [TOK_OR] = "OR",

    [TOK_CLASS_ID] = "CLASS_ID",
    [TOK_PROPERTY_ID] = "PROPERTY_ID",
    [TOK_INDIVIDUAL_ID] = "INDIVIDUAL_ID",

    [TOK_NAMESPACE_ID] = "NAMESPACE_ID",
    [TOK_DATA_TYPE] = "DATA_TYPE",

    [TOK_INTEGER] = "INTEGER",

    [TOK_LBRACKET] = "LBRACKET",
    [TOK_RBRACKET] = "RBRACKET",
    [TOK_LBRACE] = "LBRACE",
    [TOK_RBRACE] = "RBRACE",
    [TOK_LPAREN] = "LPAREN",
    [TOK_RPAREN] = "RPAREN",
    [TOK_GTE] = "GTE",
    [TOK_LTE] = "LTE",
    [TOK_GT] = "GT",
    [TOK_LT] = "LT",
    [TOK_QUOTE] = "QUOTE",
    [TOK_COMMA] = "COMMA",

    [TOK_ERROR] = "ERRO_LEXICO",
};

const char *token_type_name(TokenType type)
{
  return TOKEN_NAMES[type];
}
