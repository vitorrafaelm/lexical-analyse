/* ==========================================================================
 * main.c - Ponto de entrada do Analisador Sintático OWL2 Manchester Syntax
 *
 * Responsabilidades:
 *   - Tratar argumentos de linha de comando
 *   - Abrir o arquivo de entrada (ou usar stdin)
 *   - Inicializar a tabela de símbolos
 *   - Chamar o analisador sintático (yyparse)
 *   - Exibir a tabela de símbolos ao final
 * ========================================================================== */

#include <stdio.h>
#include <stdlib.h>
#include "token.h"
#include "symbol_table.h"
#include "semantic_analyzer.h"

/* Declarações externas do Flex e Bison */
extern FILE *yyin;
extern int yyparse(void);
extern int line_num;

int main(int argc, char **argv)
{

  symtable_init();
  semantic_init();

  printf("============================================================\n");
  printf("  Analisador Sintatico - OWL2 Manchester Syntax\n");
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

  int result = yyparse();

  if (yyin && yyin != stdin)
  {
    fclose(yyin);
  }

  semantic_finalize();
  semantic_print_report();
  symtable_print();

  semantic_destroy();

  return result == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
