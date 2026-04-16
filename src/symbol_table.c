/* ==========================================================================
 * symbol_table.c - Implementação da Tabela de Símbolos
 * ========================================================================== */

#include "symbol_table.h"
#include <stdio.h>
#include <string.h>

static Token table[MAX_SYMBOLS];
static int count = 0;

void symtable_init(void)
{
  count = 0;
}

int symtable_insert(TokenType type, const char *lexeme, int line)
{
  if (count >= MAX_SYMBOLS)
  {
    return -1;
  }

  table[count].type = type;
  table[count].line = line;
  strncpy(table[count].lexeme, lexeme, sizeof(table[count].lexeme) - 1);
  table[count].lexeme[sizeof(table[count].lexeme) - 1] = '\0';
  count++;
  return 0;
}

int symtable_size(void)
{
  return count;
}

const Token *symtable_get(int index)
{
  if (index < 0 || index >= count)
  {
    return NULL;
  }
  return &table[index];
}

void symtable_print(void)
{
  printf("\n");
  printf("  +-------+----------------------+------------------------------+\n");
  printf("  | Linha | Token                | Lexema                       |\n");
  printf("  +-------+----------------------+------------------------------+\n");

  for (int i = 0; i < count; i++)
  {
    printf("  | %-5d | %-20s | %-28s |\n",
           table[i].line,
           token_type_name(table[i].type),
           table[i].lexeme);
  }

  printf("  +-------+----------------------+------------------------------+\n");
  printf("\n  Total de tokens reconhecidos: %d\n", count);
}
