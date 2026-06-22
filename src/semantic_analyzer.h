#ifndef SEMANTIC_ANALYZER_H
#define SEMANTIC_ANALYZER_H

/*
 * Analisador semantico para OWL Manchester Syntax.
 * Responsavel por:
 *   - construir uma AST de escopos;
 *   - inferir tipos pelo contexto;
 *   - aplicar coercoes simples;
 *   - detectar uso de propriedades com sobrecarga.
 */

typedef enum
{
  SEM_TYPE_UNKNOWN = 0,
  SEM_TYPE_CLASS,
  SEM_TYPE_INDIVIDUAL,
  SEM_TYPE_PROPERTY,
  SEM_TYPE_DATATYPE,
  SEM_TYPE_INTEGER,
  SEM_TYPE_BOOLEAN
} SemanticType;

void semantic_init(void);
void semantic_destroy(void);

void semantic_start_class(const char *name, int line);
void semantic_end_class(void);

void semantic_enter_section(const char *name, int line);
void semantic_exit_section(void);

void semantic_enter_group(const char *name, int line);
void semantic_exit_group(void);

void semantic_enter_restriction(const char *property_name, int line);
void semantic_exit_restriction(void);

void semantic_set_operator(const char *op, int line);

void semantic_note_class_ref(const char *name, int line);
void semantic_note_individual_ref(const char *name, int line);
void semantic_note_property_ref(const char *name, int line);
void semantic_note_datatype_ref(const char *namespace_name, const char *datatype_name, int line);
void semantic_note_integer_literal(const char *value, int line);

void semantic_finalize(void);
void semantic_print_report(void);

int semantic_error_count(void);
int semantic_warning_count(void);

#endif