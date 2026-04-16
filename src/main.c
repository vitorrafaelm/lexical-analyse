/* ==========================================================================
 * main.c - Ponto de entrada do Analisador Léxico OWL2 Manchester Syntax
 *
 * Responsabilidades:
 *   - Tratar argumentos de linha de comando
 *   - Abrir o arquivo de entrada (ou usar stdin)
 *   - Inicializar a tabela de símbolos
 *   - Chamar o analisador léxico (yylex)
 *   - Exibir a tabela de símbolos ao final
 * ========================================================================== */

#include <stdio.h>
#include <stdlib.h>
#include "token.h"
#include "symbol_table.h"

/* Declarações externas do Flex */
extern FILE *yyin;
extern int yylex(void);

int main(int argc, char **argv)
{

  symtable_init();

  printf("============================================================\n");
  printf("  Analisador Lexico - OWL2 Manchester Syntax\n");
  printf("  Disciplina: Compiladores - UFERSA\n");
  printf("============================================================\n\n");

  if (argc > 1)
  {
    yyin = fopen(argv[1], "r");
    if (!yyin)
    {
      fprintf(stderr, "Erro: nao foi possivel abrir o arquivo '%s'\n",
              argv[1]);
      return EXIT_FAILURE;
    }
    printf("  Arquivo: %s\n\n", argv[1]);
  }
  else
  {
    printf("  Lendo da entrada padrao (stdin)...\n");
    printf("  (Digite o codigo OWL e pressione Ctrl+D para finalizar)\n\n");
  }

  printf("  %-5s  %-22s  %s\n", "LINHA", "TOKEN", "LEXEMA");
  printf("  -----  ----------------------  ----------------------------\n");

  yylex();

  if (yyin && yyin != stdin)
  {
    fclose(yyin);
  }

  symtable_print();

  return EXIT_SUCCESS;
}
