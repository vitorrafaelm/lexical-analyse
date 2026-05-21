

#ifndef TOKEN_H
#define TOKEN_H

/* Estrutura que representa um token reconhecido */
typedef struct
{
  int type; /* Código do token (definido pelo Bison em owl_parser.tab.h) */
  char lexeme[256];
  int line;
} Token;

/* Retorna o nome legível de um tipo de token */
const char *token_type_name(int type);

#endif
