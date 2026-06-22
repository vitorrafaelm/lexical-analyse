%{
/* ==========================================================================
 * owl_parser.y - Analisador Sintático para OWL2 Manchester Syntax (Bison)
 *
 * Disciplina: Compiladores - UFERSA
 *
 * Responsabilidades:
 *   - Validar a estrutura sintática das declarações de classes OWL2
 *   - Classificar cada classe (Primitiva, Definida, Fechamento, Coberta,
 *     Enumerada, Aninhada)
 *   - Reportar erros sintáticos com número de linha e sugestão
 * ========================================================================== */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "token.h"
#include "semantic_analyzer.h"

/* Variáveis externas do Flex */
extern int yylex(void);
extern int line_num;
extern char *yytext;
extern FILE *yyin;

/* Protótipo de tratamento de erro */
void yyerror(const char *msg);

/* ---------- Variáveis de classificação por classe ---------- */

/* Nome da classe sendo analisada */
static char current_class[256] = "";

/* Flags de classificação (resetadas a cada class_decl) */
static int has_subclassof   = 0;
static int has_equivalentto = 0;
static int has_closure       = 0;  /* usa 'only (X or Y)' */
static int has_covering      = 0;  /* EquivalentTo: ClassID or ClassID ... */
static int has_enumeration   = 0;  /* EquivalentTo: { Ind1, Ind2 }        */
static int has_nesting       = 0;  /* restrição cujo alvo é outra restrição */

/* Nível de profundidade de restrição (para detectar aninhamento) */
static int restriction_depth = 0;

/* Contadores de estatísticas globais */
static int total_classes = 0;
static int total_errors  = 0;

/* Flag para saber se EquivalentTo contém propriedade (vs. coberta) */
static int equiv_has_property = 0;

/* Flag para rastrear se 'only' aparece dentro de uma expressão com 'or' */
static int inside_only = 0;
static int only_has_or = 0;

/* ---------- Funções auxiliares ---------- */

static void reset_class_flags(void)
{
    current_class[0]   = '\0';
    has_subclassof     = 0;
    has_equivalentto   = 0;
    has_closure        = 0;
    has_covering       = 0;
    has_enumeration    = 0;
    has_nesting        = 0;
    equiv_has_property = 0;
}

static void print_classification(void)
{
    total_classes++;

    printf("\n  Classe: %s\n", current_class);

    /* Tipo base: Definida (tem EquivalentTo) ou Primitiva */
    if (has_equivalentto)
        printf("    Tipo base:       Definida\n");
    else
        printf("    Tipo base:       Primitiva\n");

    /* Características adicionais */
    int has_extra = 0;
    printf("    Caracteristicas:");

    if (has_enumeration) {
        printf(" Enumerada");
        has_extra = 1;
    }
    if (has_covering) {
        if (has_extra) printf(",");
        printf(" Coberta (covering)");
        has_extra = 1;
    }
    if (has_closure) {
        if (has_extra) printf(",");
        printf(" Fechamento (closure)");
        has_extra = 1;
    }
    if (has_nesting) {
        if (has_extra) printf(",");
        printf(" Aninhada");
        has_extra = 1;
    }

    if (!has_extra)
        printf(" Nenhuma");

    printf("\n");
}

%}

/* ---------- Mensagens de erro detalhadas ---------- */
%error-verbose

/* ---------- União semântica ---------- */
%union {
    char str[256];
}

/* ---------- Declaração de tokens ---------- */

/* Palavras-chave OWL (seguidas de ':') */
%token <str> TOK_CLASS
%token <str> TOK_EQUIVALENT_TO
%token <str> TOK_INDIVIDUALS
%token <str> TOK_SUBCLASS_OF
%token <str> TOK_DISJOINT_CLASSES

/* Palavras reservadas */
%token <str> TOK_SOME
%token <str> TOK_ALL
%token <str> TOK_ONLY
%token <str> TOK_VALUE
%token <str> TOK_MIN
%token <str> TOK_MAX
%token <str> TOK_EXACTLY
%token <str> TOK_THAT
%token <str> TOK_NOT
%token <str> TOK_AND
%token <str> TOK_OR

/* Identificadores */
%token <str> TOK_CLASS_ID
%token <str> TOK_PROPERTY_ID
%token <str> TOK_INDIVIDUAL_ID

/* Tipos de dados e namespaces */
%token <str> TOK_NAMESPACE_ID
%token <str> TOK_DATA_TYPE

/* Literais */
%token <str> TOK_INTEGER

/* Símbolos especiais */
%token <str> TOK_LBRACKET
%token <str> TOK_RBRACKET
%token <str> TOK_LBRACE
%token <str> TOK_RBRACE
%token <str> TOK_LPAREN
%token <str> TOK_RPAREN
%token <str> TOK_GTE
%token <str> TOK_LTE
%token <str> TOK_GT
%token <str> TOK_LT
%token <str> TOK_QUOTE
%token <str> TOK_COMMA

/* Erro léxico */
%token <str> TOK_ERROR

/* Símbolo inicial */
%start ontology

%%

/* ===================================================================== */
/* 4.1 Estrutura do Arquivo                                              */
/* ===================================================================== */

ontology
    : class_list
    ;

class_list
    : class_decl class_list
    | /* vazio */
    ;

/* ===================================================================== */
/* 4.2 Declaração de Classe                                              */
/* ===================================================================== */

class_decl
    : TOK_CLASS TOK_CLASS_ID
      {
          reset_class_flags();
          strncpy(current_class, $2, 255);
          current_class[255] = '\0';
          semantic_start_class($2, line_num);
      }
      class_body
      {
          print_classification();
          semantic_end_class();
      }
    ;

class_body
    : section class_body
    | /* vazio */
    ;

section
    : TOK_SUBCLASS_OF
      {
          has_subclassof = 1;
          semantic_enter_section("SubClassOf", line_num);
      }
      desc_comma_list
      {
          semantic_exit_section();
      }
    | TOK_EQUIVALENT_TO
      {
          has_equivalentto = 1;
          equiv_has_property = 0;
          semantic_enter_section("EquivalentTo", line_num);
      }
      equiv_body
      {
          semantic_exit_section();
      }
    | TOK_DISJOINT_CLASSES
      {
          semantic_enter_section("DisjointClasses", line_num);
      }
      classid_comma_list
      {
          semantic_exit_section();
      }
    | TOK_INDIVIDUALS
      {
          semantic_enter_section("Individuals", line_num);
      }
      indref_comma_list
      {
          semantic_exit_section();
      }
    ;

/* ===================================================================== */
/* 4.3 Seção SubClassOf (lista com vírgula)                              */
/* ===================================================================== */

desc_comma_list
    : or_expr desc_comma_tail
    ;

desc_comma_tail
    : TOK_COMMA or_expr desc_comma_tail
    | /* vazio */
    ;

/* ===================================================================== */
/* 4.4 Seção EquivalentTo                                                */
/* ===================================================================== */

equiv_body
    : enumeration
      {
          has_enumeration = 1;
      }
    | equiv_or_expr
    ;

/* ===================================================================== */
/* Expressão OR específica para EquivalentTo (detecta coberta)           */
/* ===================================================================== */

equiv_or_expr
    : and_expr equiv_or_tail
    ;

equiv_or_tail
    : TOK_OR and_expr equiv_or_tail
      {
          /* Se EquivalentTo tem OR e nenhuma propriedade, é coberta */
          if (!equiv_has_property)
              has_covering = 1;
      }
    | /* vazio */
    ;

/* ===================================================================== */
/* 4.5 Enumeração (Classe Enumerada)                                     */
/* ===================================================================== */

enumeration
    : TOK_LBRACE ind_comma_list TOK_RBRACE
    ;

ind_comma_list
    : TOK_INDIVIDUAL_ID
      {
          semantic_note_individual_ref($1, line_num);
      }
      ind_comma_tail
    ;

ind_comma_tail
    : TOK_COMMA TOK_INDIVIDUAL_ID
      {
          semantic_note_individual_ref($2, line_num);
      }
      ind_comma_tail
    | /* vazio */
    ;

/* ===================================================================== */
/* 4.6 Expressão OR (Disjunção — precedência mais baixa)                 */
/* ===================================================================== */

or_expr
    : and_expr or_tail
    ;

or_tail
    : TOK_OR and_expr or_tail
    | /* vazio */
    ;

/* ===================================================================== */
/* 4.7 Expressão AND (Conjunção)                                         */
/* ===================================================================== */

and_expr
    : unary and_tail
    ;

and_tail
    : TOK_AND unary and_tail
    | /* vazio */
    ;

/* ===================================================================== */
/* 4.8 Expressão Unária (Negação)                                        */
/* ===================================================================== */

unary
    : TOK_NOT unary
    | primary
    ;

/* ===================================================================== */
/* 4.9 Expressão Primária (Atômica)                                      */
/* ===================================================================== */

primary
    : TOK_CLASS_ID
      {
          semantic_note_class_ref($1, line_num);
      }
    | restriction
    | TOK_LPAREN
      {
          semantic_enter_group("ParenthesizedExpr", line_num);
      }
      or_expr TOK_RPAREN
      {
          semantic_exit_group();
      }
    ;

/* ===================================================================== */
/* 4.10 Restrição de Propriedade (Fatorada)                              */
/* ===================================================================== */

restriction
    : TOK_PROPERTY_ID
      {
          equiv_has_property = 1;
          restriction_depth++;
          semantic_enter_restriction($1, line_num);
      }
      restriction_tail
      {
          restriction_depth--;
          semantic_exit_restriction();
      }
    ;

restriction_tail
        : TOK_SOME
            {
                    semantic_set_operator("some", line_num);
            }
            object
        | TOK_ALL
            {
                    semantic_set_operator("all", line_num);
            }
            object
    | TOK_ONLY
      {
          inside_only++;
          only_has_or = 0;
                    semantic_set_operator("only", line_num);
      }
      only_object
      {
          inside_only--;
          if (only_has_or)
              has_closure = 1;
      }
        | TOK_VALUE
            {
                    semantic_set_operator("value", line_num);
            }
            value_obj
        | TOK_MIN TOK_INTEGER
            {
                    semantic_set_operator("min", line_num);
                    semantic_note_integer_literal($2, line_num);
            }
            card_obj
        | TOK_MAX TOK_INTEGER
            {
                    semantic_set_operator("max", line_num);
                    semantic_note_integer_literal($2, line_num);
            }
            card_obj
        | TOK_EXACTLY TOK_INTEGER
            {
                    semantic_set_operator("exactly", line_num);
                    semantic_note_integer_literal($2, line_num);
            }
            card_obj
    ;

/* ===================================================================== */
/* Objeto após ONLY (detecta closure: only (X or Y))                     */
/* ===================================================================== */

only_object
    : TOK_CLASS_ID
      {
          semantic_note_class_ref($1, line_num);
      }
    | datatype facet_opt
    | TOK_LPAREN
      {
          semantic_enter_group("OnlyExpr", line_num);
      }
      only_or_expr TOK_RPAREN
      {
          semantic_exit_group();
      }
    ;

only_or_expr
    : only_and_expr only_or_tail
    ;

only_or_tail
    : TOK_OR
      {
          only_has_or = 1;
      }
      only_and_expr only_or_tail
    | /* vazio */
    ;

only_and_expr
    : only_unary only_and_tail
    ;

only_and_tail
    : TOK_AND only_unary only_and_tail
    | /* vazio */
    ;

only_unary
    : TOK_NOT only_unary
    | only_primary
    ;

only_primary
    : TOK_CLASS_ID
      {
          semantic_note_class_ref($1, line_num);
      }
    | only_restriction
    | TOK_LPAREN
      {
          semantic_enter_group("OnlyNestedExpr", line_num);
      }
      only_or_expr TOK_RPAREN
      {
          semantic_exit_group();
      }
    ;

only_restriction
    : TOK_PROPERTY_ID
      {
          equiv_has_property = 1;
          restriction_depth++;
      }
      restriction_tail
      {
          restriction_depth--;
      }
    ;

/* ===================================================================== */
/* 4.11 Alvo de SOME / ALL                                               */
/* ===================================================================== */

object
    : TOK_CLASS_ID
      {
          semantic_note_class_ref($1, line_num);
      }
    | datatype facet_opt
    | TOK_LPAREN
      {
          if (restriction_depth > 0)
              has_nesting = 1;
          semantic_enter_group("RestrictionTarget", line_num);
      }
      or_expr TOK_RPAREN
      {
          semantic_exit_group();
      }
    ;

/* ===================================================================== */
/* 4.12 Alvo de VALUE                                                    */
/* ===================================================================== */

value_obj
        : TOK_CLASS_ID
            {
                    semantic_note_class_ref($1, line_num);
            }
        | TOK_INDIVIDUAL_ID
            {
                    semantic_note_individual_ref($1, line_num);
            }
        | TOK_PROPERTY_ID
            {
                    semantic_note_property_ref($1, line_num);
            }
    ;

/* ===================================================================== */
/* 4.13 Alvo de Cardinalidade (MIN / MAX / EXACTLY)                      */
/* ===================================================================== */

card_obj
    : TOK_CLASS_ID
      {
          semantic_note_class_ref($1, line_num);
      }
    | datatype facet_opt
    | /* vazio */
    ;

/* ===================================================================== */
/* 4.14 Tipo de Dado e Facetas                                           */
/* ===================================================================== */

datatype
    : TOK_NAMESPACE_ID TOK_DATA_TYPE
      {
          semantic_note_datatype_ref($1, $2, line_num);
      }
    ;

facet_opt
    : TOK_LBRACKET comp TOK_INTEGER TOK_RBRACKET
    | /* vazio */
    ;

comp
    : TOK_GTE
    | TOK_LTE
    | TOK_GT
    | TOK_LT
    ;

/* ===================================================================== */
/* 4.15 Seção DisjointClasses                                            */
/* ===================================================================== */

classid_comma_list
    : TOK_CLASS_ID
      {
          semantic_note_class_ref($1, line_num);
      }
      classid_comma_tail
    ;

classid_comma_tail
    : TOK_COMMA TOK_CLASS_ID
      {
          semantic_note_class_ref($2, line_num);
      }
      classid_comma_tail
    | /* vazio */
    ;

/* ===================================================================== */
/* 4.16 Seção Individuals                                                */
/* ===================================================================== */

indref_comma_list
    : TOK_INDIVIDUAL_ID
      {
          semantic_note_individual_ref($1, line_num);
      }
      indref_comma_tail
    ;

indref_comma_tail
    : TOK_COMMA TOK_INDIVIDUAL_ID
      {
          semantic_note_individual_ref($2, line_num);
      }
      indref_comma_tail
    | /* vazio */
    ;

%%

/* ===================================================================== */
/* Tratamento de erros                                                    */
/* ===================================================================== */

/* Traduz nomes de tokens internos do Bison para nomes legíveis em português */
static const char *traduzir_token(const char *tok)
{
    if (strstr(tok, "TOK_CLASS_ID"))        return "identificador de classe (ex: Pizza)";
    if (strstr(tok, "TOK_PROPERTY_ID"))     return "identificador de propriedade (ex: hasTopping)";
    if (strstr(tok, "TOK_INDIVIDUAL_ID"))   return "identificador de individuo (ex: Pizza1)";
    if (strstr(tok, "TOK_CLASS'") || strcmp(tok, "TOK_CLASS") == 0)
                                            return "'Class:'";
    if (strstr(tok, "TOK_SUBCLASS_OF"))     return "'SubClassOf:'";
    if (strstr(tok, "TOK_EQUIVALENT_TO"))   return "'EquivalentTo:'";
    if (strstr(tok, "TOK_DISJOINT_CLASSES"))return "'DisjointClasses:'";
    if (strstr(tok, "TOK_INDIVIDUALS"))     return "'Individuals:'";
    if (strstr(tok, "TOK_SOME"))            return "'some'";
    if (strstr(tok, "TOK_ALL"))             return "'all'";
    if (strstr(tok, "TOK_ONLY"))            return "'only'";
    if (strstr(tok, "TOK_VALUE"))           return "'value'";
    if (strstr(tok, "TOK_MIN"))             return "'min'";
    if (strstr(tok, "TOK_MAX"))             return "'max'";
    if (strstr(tok, "TOK_EXACTLY"))         return "'exactly'";
    if (strstr(tok, "TOK_NOT"))             return "'not'";
    if (strstr(tok, "TOK_AND"))             return "'and'";
    if (strstr(tok, "TOK_OR"))              return "'or'";
    if (strstr(tok, "TOK_LPAREN"))          return "'('";
    if (strstr(tok, "TOK_RPAREN"))          return "')'";
    if (strstr(tok, "TOK_LBRACE"))          return "'{'";
    if (strstr(tok, "TOK_RBRACE"))          return "'}'";
    if (strstr(tok, "TOK_LBRACKET"))        return "'['";
    if (strstr(tok, "TOK_RBRACKET"))        return "']'";
    if (strstr(tok, "TOK_COMMA"))           return "','";
    if (strstr(tok, "TOK_NAMESPACE_ID"))    return "namespace (ex: xsd:)";
    if (strstr(tok, "TOK_DATA_TYPE"))       return "tipo de dado (ex: integer)";
    if (strstr(tok, "TOK_INTEGER"))         return "numero inteiro";
    if (strstr(tok, "TOK_GTE"))             return "'>='";
    if (strstr(tok, "TOK_LTE"))             return "'<='";
    if (strstr(tok, "TOK_GT"))              return "'>'";
    if (strstr(tok, "TOK_LT"))              return "'<'";
    if (strstr(tok, "$end"))                return "fim do arquivo";
    return tok;
}

void yyerror(const char *msg)
{
    total_errors++;
    fprintf(stderr, "\n  ERRO SINTATICO na linha %d:\n", line_num);
    fprintf(stderr, "    Token inesperado: \"%s\"\n", yytext);

    if (current_class[0] != '\0')
        fprintf(stderr, "    Na classe: %s\n", current_class);

    /* Extrair tokens esperados da mensagem verbose do Bison */
    const char *expecting = strstr(msg, "expecting");
    if (expecting) {
        fprintf(stderr, "    Dica: nesta posicao era esperado: ");
        /* Percorre a string de expecting e traduz cada token */
        const char *p = expecting + 10; /* pula "expecting " */
        int first = 1;
        while (*p) {
            /* Pula espaços e separadores */
            while (*p == ' ' || *p == '\n') p++;
            if (*p == '\0') break;
            if (strncmp(p, "or", 2) == 0 && (p[2] == ' ' || p[2] == '\0')) {
                p += 2;
                continue;
            }
            /* Captura o nome do token */
            char tokbuf[64];
            int i = 0;
            while (*p && *p != ' ' && *p != '\n' && i < 63) {
                tokbuf[i++] = *p++;
            }
            tokbuf[i] = '\0';
            if (tokbuf[0] == '\0') continue;

            if (!first) fprintf(stderr, ", ");
            fprintf(stderr, "%s", traduzir_token(tokbuf));
            first = 0;
        }
        fprintf(stderr, "\n");
    } else {
        fprintf(stderr, "    Mensagem: %s\n", msg);
    }

    fprintf(stderr, "\n");
}
