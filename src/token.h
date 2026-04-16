/* ==========================================================================
 * token.h - Definição dos tipos de tokens da linguagem OWL2 Manchester Syntax
 * ========================================================================== */

#ifndef TOKEN_H
#define TOKEN_H

/* Tipos de tokens reconhecidos pelo analisador léxico */
typedef enum
{
  /* Palavras-chave OWL (seguidas de ':') */
  TOK_CLASS,
  TOK_EQUIVALENT_TO,
  TOK_INDIVIDUALS,
  TOK_SUBCLASS_OF,
  TOK_DISJOINT_CLASSES,

  /* Palavras reservadas */
  TOK_SOME,
  TOK_ALL,
  TOK_ONLY,
  TOK_VALUE,
  TOK_MIN,
  TOK_MAX,
  TOK_EXACTLY,
  TOK_THAT,
  TOK_NOT,
  TOK_AND,
  TOK_OR,

  /* Identificadores */
  TOK_CLASS_ID,
  TOK_PROPERTY_ID,
  TOK_INDIVIDUAL_ID,

  /* Tipos de dados e namespaces */
  TOK_NAMESPACE_ID,
  TOK_DATA_TYPE,

  /* Literais */
  TOK_INTEGER,

  /* Símbolos especiais */
  TOK_LBRACKET,
  TOK_RBRACKET,
  TOK_LBRACE,
  TOK_RBRACE,
  TOK_LPAREN,
  TOK_RPAREN,
  TOK_GTE,
  TOK_LTE,
  TOK_GT,
  TOK_LT,
  TOK_QUOTE,
  TOK_COMMA,

  /* Erro */
  TOK_ERROR
} TokenType;

/* Estrutura que representa um token reconhecido */
typedef struct
{
  TokenType type;
  char lexeme[256];
  int line;
} Token;

/* Retorna o nome legível de um tipo de token */
const char *token_type_name(TokenType type);

#endif
