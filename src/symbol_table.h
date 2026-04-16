/* ==========================================================================
 * symbol_table.h - Cabeçalho da Tabela de Símbolos
 *
 * A tabela de símbolos armazena todos os tokens reconhecidos pelo
 * analisador léxico.
 * ========================================================================== */

#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include "token.h"

#define MAX_SYMBOLS 5000

/* Inicializa a tabela de símbolos */
void symtable_init(void);

/* Insere um token na tabela. Retorna 0 se ok, -1 se cheia. */
int symtable_insert(TokenType type, const char *lexeme, int line);

/* Retorna a quantidade de tokens armazenados */
int symtable_size(void);

/* Retorna o token na posição 'index' (NULL se inválido) */
const Token *symtable_get(int index);

/* Imprime a tabela de símbolos formatada na saída padrão */
void symtable_print(void);

#endif
