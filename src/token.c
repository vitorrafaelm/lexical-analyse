
#include "token.h"
#include "owl_parser.tab.h"

const char *token_type_name(int type)
{
  switch (type)
  {
  case TOK_CLASS:
    return "CLASS";
  case TOK_EQUIVALENT_TO:
    return "EQUIVALENT_TO";
  case TOK_INDIVIDUALS:
    return "INDIVIDUALS";
  case TOK_SUBCLASS_OF:
    return "SUBCLASS_OF";
  case TOK_DISJOINT_CLASSES:
    return "DISJOINT_CLASSES";
  case TOK_SOME:
    return "SOME";
  case TOK_ALL:
    return "ALL";
  case TOK_ONLY:
    return "ONLY";
  case TOK_VALUE:
    return "VALUE";
  case TOK_MIN:
    return "MIN";
  case TOK_MAX:
    return "MAX";
  case TOK_EXACTLY:
    return "EXACTLY";
  case TOK_THAT:
    return "THAT";
  case TOK_NOT:
    return "NOT";
  case TOK_AND:
    return "AND";
  case TOK_OR:
    return "OR";
  case TOK_CLASS_ID:
    return "CLASS_ID";
  case TOK_PROPERTY_ID:
    return "PROPERTY_ID";
  case TOK_INDIVIDUAL_ID:
    return "INDIVIDUAL_ID";
  case TOK_NAMESPACE_ID:
    return "NAMESPACE_ID";
  case TOK_DATA_TYPE:
    return "DATA_TYPE";
  case TOK_INTEGER:
    return "INTEGER";
  case TOK_LBRACKET:
    return "LBRACKET";
  case TOK_RBRACKET:
    return "RBRACKET";
  case TOK_LBRACE:
    return "LBRACE";
  case TOK_RBRACE:
    return "RBRACE";
  case TOK_LPAREN:
    return "LPAREN";
  case TOK_RPAREN:
    return "RPAREN";
  case TOK_GTE:
    return "GTE";
  case TOK_LTE:
    return "LTE";
  case TOK_GT:
    return "GT";
  case TOK_LT:
    return "LT";
  case TOK_QUOTE:
    return "QUOTE";
  case TOK_COMMA:
    return "COMMA";
  case TOK_ERROR:
    return "ERRO_LEXICO";
  default:
    return "DESCONHECIDO";
  }
}
