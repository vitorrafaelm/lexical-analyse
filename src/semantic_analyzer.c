#include "semantic_analyzer.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_SEM_NODES 8192
#define MAX_NAME_LEN 128
#define MAX_CLASSES 2048
#define MAX_REFS 4096
#define MAX_PROPERTIES 2048

typedef enum
{
  NODE_ONTOLOGY = 0,
  NODE_CLASS,
  NODE_SECTION,
  NODE_GROUP,
  NODE_RESTRICTION
} NodeKind;

typedef enum
{
  EXPECT_NONE = 0,
  EXPECT_CLASS_OR_DATATYPE,
  EXPECT_VALUE,
  EXPECT_CARDINALITY_INTEGER,
  EXPECT_CARDINALITY_TARGET
} ExpectedKind;

typedef struct SemNode
{
  NodeKind kind;
  char label[MAX_NAME_LEN];
  int line;
  struct SemNode *parent;
  struct SemNode *first_child;
  struct SemNode *last_child;
  struct SemNode *next_sibling;
} SemNode;

typedef struct
{
  char name[MAX_NAME_LEN];
  int line;
} NamedRef;

typedef struct
{
  char property[MAX_NAME_LEN];
  int use_count;
  unsigned int operator_mask;
  unsigned int rhs_type_mask;
} PropertyProfile;

static SemNode nodes[MAX_SEM_NODES];
static int node_count = 0;

static SemNode *root_scope = NULL;
static SemNode *current_class_scope = NULL;
static SemNode *current_section_scope = NULL;
static SemNode *current_group_scope = NULL;
static SemNode *current_restriction_scope = NULL;

static char current_property[MAX_NAME_LEN] = "";
static char current_operator[MAX_NAME_LEN] = "";
static ExpectedKind current_expectation = EXPECT_NONE;

static NamedRef declared_classes[MAX_CLASSES];
static int declared_class_count = 0;
static NamedRef class_references[MAX_REFS];
static int class_ref_count = 0;

static PropertyProfile properties[MAX_PROPERTIES];
static int property_count = 0;

static int sem_errors = 0;
static int sem_warnings = 0;
static int sem_inferences = 0;
static int sem_coercions = 0;
static int sem_overloads = 0;

static const char *node_kind_name(NodeKind kind)
{
  switch (kind)
  {
  case NODE_ONTOLOGY:
    return "ONTOLOGY";
  case NODE_CLASS:
    return "CLASS";
  case NODE_SECTION:
    return "SECTION";
  case NODE_GROUP:
    return "GROUP";
  case NODE_RESTRICTION:
    return "RESTRICTION";
  default:
    return "UNKNOWN";
  }
}

static int type_bit(SemanticType type)
{
  return 1U << (unsigned int)type;
}

static void copy_name(char *dst, const char *src)
{
  strncpy(dst, src, MAX_NAME_LEN - 1);
  dst[MAX_NAME_LEN - 1] = '\0';
}

static SemNode *new_node(NodeKind kind, const char *label, int line)
{
  if (node_count >= MAX_SEM_NODES)
  {
    sem_errors++;
    return NULL;
  }

  SemNode *node = &nodes[node_count++];
  node->kind = kind;
  copy_name(node->label, label ? label : "");
  node->line = line;
  node->parent = NULL;
  node->first_child = NULL;
  node->last_child = NULL;
  node->next_sibling = NULL;
  return node;
}

static void attach_child(SemNode *parent, SemNode *child)
{
  if (!parent || !child)
  {
    return;
  }

  child->parent = parent;
  if (!parent->first_child)
  {
    parent->first_child = child;
    parent->last_child = child;
    return;
  }

  parent->last_child->next_sibling = child;
  parent->last_child = child;
}

static SemNode *active_parent_scope(void)
{
  if (current_restriction_scope)
  {
    return current_restriction_scope;
  }
  if (current_group_scope)
  {
    return current_group_scope;
  }
  if (current_section_scope)
  {
    return current_section_scope;
  }
  if (current_class_scope)
  {
    return current_class_scope;
  }
  return root_scope;
}

static int class_declared(const char *name)
{
  for (int i = 0; i < declared_class_count; i++)
  {
    if (strcmp(declared_classes[i].name, name) == 0)
    {
      return 1;
    }
  }
  return 0;
}

static void declare_class(const char *name, int line)
{
  if (class_declared(name))
  {
    sem_errors++;
    fprintf(stderr, "  ERRO SEMANTICO linha %d: classe '%s' redeclarada.\n", line, name);
    return;
  }

  if (declared_class_count < MAX_CLASSES)
  {
    copy_name(declared_classes[declared_class_count].name, name);
    declared_classes[declared_class_count].line = line;
    declared_class_count++;
  }
}

static void add_class_reference(const char *name, int line)
{
  if (class_ref_count >= MAX_REFS)
  {
    return;
  }

  copy_name(class_references[class_ref_count].name, name);
  class_references[class_ref_count].line = line;
  class_ref_count++;
}

static PropertyProfile *find_property_profile(const char *name)
{
  for (int i = 0; i < property_count; i++)
  {
    if (strcmp(properties[i].property, name) == 0)
    {
      return &properties[i];
    }
  }

  if (property_count >= MAX_PROPERTIES)
  {
    sem_errors++;
    return NULL;
  }

  PropertyProfile *created = &properties[property_count++];
  copy_name(created->property, name);
  created->use_count = 0;
  created->operator_mask = 0;
  created->rhs_type_mask = 0;
  return created;
}

static int count_bits(unsigned int value)
{
  int count = 0;
  while (value)
  {
    count += (value & 1U) ? 1 : 0;
    value >>= 1U;
  }
  return count;
}

static void set_rhs_type(SemanticType type)
{
  if (current_property[0] == '\0')
  {
    return;
  }

  PropertyProfile *profile = find_property_profile(current_property);
  if (!profile)
  {
    return;
  }

  profile->rhs_type_mask |= (unsigned int)type_bit(type);
}

static void infer_from_context(SemanticType got_type, const char *lexeme, int line)
{
  if (current_expectation == EXPECT_NONE)
  {
    return;
  }

  if (current_expectation == EXPECT_CLASS_OR_DATATYPE)
  {
    if (got_type == SEM_TYPE_CLASS || got_type == SEM_TYPE_DATATYPE)
    {
      sem_inferences++;
      set_rhs_type(got_type);
      return;
    }

    sem_errors++;
    fprintf(stderr,
            "  ERRO SEMANTICO linha %d: operador '%s' exige classe/datatype, recebido '%s'.\n",
            line,
            current_operator,
            lexeme);
    return;
  }

  if (current_expectation == EXPECT_CARDINALITY_INTEGER)
  {
    if (got_type == SEM_TYPE_INTEGER)
    {
      sem_inferences++;
      current_expectation = EXPECT_CARDINALITY_TARGET;
      return;
    }

    sem_errors++;
    fprintf(stderr,
            "  ERRO SEMANTICO linha %d: cardinalidade de '%s' exige inteiro.\n",
            line,
            current_operator);
    return;
  }

  if (current_expectation == EXPECT_CARDINALITY_TARGET)
  {
    if (got_type == SEM_TYPE_CLASS || got_type == SEM_TYPE_DATATYPE || got_type == SEM_TYPE_UNKNOWN)
    {
      sem_inferences++;
      set_rhs_type(got_type == SEM_TYPE_UNKNOWN ? SEM_TYPE_CLASS : got_type);
      return;
    }

    sem_warnings++;
    fprintf(stderr,
            "  AVISO SEMANTICO linha %d: alvo inesperado apos cardinalidade em '%s'.\n",
            line,
            current_property);
    return;
  }

  if (current_expectation == EXPECT_VALUE)
  {
    if (got_type == SEM_TYPE_CLASS || got_type == SEM_TYPE_INDIVIDUAL || got_type == SEM_TYPE_BOOLEAN || got_type == SEM_TYPE_INTEGER)
    {
      sem_inferences++;
      set_rhs_type(got_type);
      return;
    }

    sem_warnings++;
    fprintf(stderr,
            "  AVISO SEMANTICO linha %d: valor '%s' nao usual para operador value.\n",
            line,
            lexeme);
  }
}

static void print_tree_rec(const SemNode *node, int depth)
{
  if (!node)
  {
    return;
  }

  for (int i = 0; i < depth; i++)
  {
    printf("  ");
  }
  printf("- [%s] %s (linha %d)\n", node_kind_name(node->kind), node->label, node->line);

  for (const SemNode *child = node->first_child; child; child = child->next_sibling)
  {
    print_tree_rec(child, depth + 1);
  }
}

void semantic_init(void)
{
  node_count = 0;
  root_scope = NULL;
  current_class_scope = NULL;
  current_section_scope = NULL;
  current_group_scope = NULL;
  current_restriction_scope = NULL;
  current_property[0] = '\0';
  current_operator[0] = '\0';
  current_expectation = EXPECT_NONE;

  declared_class_count = 0;
  class_ref_count = 0;
  property_count = 0;

  sem_errors = 0;
  sem_warnings = 0;
  sem_inferences = 0;
  sem_coercions = 0;
  sem_overloads = 0;

  root_scope = new_node(NODE_ONTOLOGY, "Ontology", 1);
}

void semantic_destroy(void)
{
  semantic_init();
}

void semantic_start_class(const char *name, int line)
{
  if (!root_scope)
  {
    semantic_init();
  }

  SemNode *class_node = new_node(NODE_CLASS, name, line);
  attach_child(root_scope, class_node);
  current_class_scope = class_node;
  current_section_scope = NULL;
  current_group_scope = NULL;
  current_restriction_scope = NULL;
  current_property[0] = '\0';
  current_operator[0] = '\0';
  current_expectation = EXPECT_NONE;

  declare_class(name, line);
}

void semantic_end_class(void)
{
  current_class_scope = NULL;
  current_section_scope = NULL;
  current_group_scope = NULL;
  current_restriction_scope = NULL;
  current_property[0] = '\0';
  current_operator[0] = '\0';
  current_expectation = EXPECT_NONE;
}

void semantic_enter_section(const char *name, int line)
{
  SemNode *parent = current_class_scope ? current_class_scope : root_scope;
  SemNode *node = new_node(NODE_SECTION, name, line);
  attach_child(parent, node);
  current_section_scope = node;
  current_group_scope = NULL;
  current_restriction_scope = NULL;
  current_expectation = EXPECT_NONE;
}

void semantic_exit_section(void)
{
  current_section_scope = NULL;
  current_group_scope = NULL;
  current_restriction_scope = NULL;
  current_expectation = EXPECT_NONE;
}

void semantic_enter_group(const char *name, int line)
{
  SemNode *node = new_node(NODE_GROUP, name, line);
  attach_child(active_parent_scope(), node);
  current_group_scope = node;
}

void semantic_exit_group(void)
{
  if (current_group_scope)
  {
    current_group_scope = current_group_scope->parent;
    if (current_group_scope && current_group_scope->kind != NODE_GROUP)
    {
      current_group_scope = NULL;
    }
  }
}

void semantic_enter_restriction(const char *property_name, int line)
{
  SemNode *node = new_node(NODE_RESTRICTION, property_name, line);
  attach_child(active_parent_scope(), node);
  current_restriction_scope = node;
  copy_name(current_property, property_name);
  current_operator[0] = '\0';
  current_expectation = EXPECT_NONE;

  PropertyProfile *profile = find_property_profile(property_name);
  if (profile)
  {
    profile->use_count++;
  }
}

void semantic_exit_restriction(void)
{
  if (current_restriction_scope)
  {
    SemNode *parent = current_restriction_scope->parent;
    current_restriction_scope = NULL;
    while (parent && parent->kind == NODE_GROUP)
    {
      parent = parent->parent;
    }
  }

  current_property[0] = '\0';
  current_operator[0] = '\0';
  current_expectation = EXPECT_NONE;
}

void semantic_set_operator(const char *op, int line)
{
  (void)line;
  copy_name(current_operator, op);

  PropertyProfile *profile = find_property_profile(current_property);
  if (profile)
  {
    if (strcmp(op, "some") == 0)
      profile->operator_mask |= 1U << 0;
    else if (strcmp(op, "all") == 0)
      profile->operator_mask |= 1U << 1;
    else if (strcmp(op, "only") == 0)
      profile->operator_mask |= 1U << 2;
    else if (strcmp(op, "value") == 0)
      profile->operator_mask |= 1U << 3;
    else if (strcmp(op, "min") == 0)
      profile->operator_mask |= 1U << 4;
    else if (strcmp(op, "max") == 0)
      profile->operator_mask |= 1U << 5;
    else if (strcmp(op, "exactly") == 0)
      profile->operator_mask |= 1U << 6;
  }

  if (strcmp(op, "value") == 0)
  {
    current_expectation = EXPECT_VALUE;
    return;
  }

  if (strcmp(op, "min") == 0 || strcmp(op, "max") == 0 || strcmp(op, "exactly") == 0)
  {
    current_expectation = EXPECT_CARDINALITY_INTEGER;
    return;
  }

  current_expectation = EXPECT_CLASS_OR_DATATYPE;
}

void semantic_note_class_ref(const char *name, int line)
{
  add_class_reference(name, line);
  infer_from_context(SEM_TYPE_CLASS, name, line);
}

void semantic_note_individual_ref(const char *name, int line)
{
  infer_from_context(SEM_TYPE_INDIVIDUAL, name, line);
}

void semantic_note_property_ref(const char *name, int line)
{
  if (strcmp(name, "true") == 0 || strcmp(name, "false") == 0)
  {
    sem_coercions++;
    infer_from_context(SEM_TYPE_BOOLEAN, name, line);
    return;
  }

  infer_from_context(SEM_TYPE_PROPERTY, name, line);
}

void semantic_note_datatype_ref(const char *namespace_name, const char *datatype_name, int line)
{
  (void)namespace_name;
  infer_from_context(SEM_TYPE_DATATYPE, datatype_name, line);
}

void semantic_note_integer_literal(const char *value, int line)
{
  infer_from_context(SEM_TYPE_INTEGER, value, line);
}

void semantic_finalize(void)
{
  for (int i = 0; i < class_ref_count; i++)
  {
    if (!class_declared(class_references[i].name))
    {
      sem_warnings++;
      fprintf(stderr,
              "  AVISO SEMANTICO linha %d: referencia a classe '%s' nao declarada no arquivo.\n",
              class_references[i].line,
              class_references[i].name);
    }
  }

  for (int i = 0; i < property_count; i++)
  {
    int rhs_type_count = count_bits(properties[i].rhs_type_mask);
    if (rhs_type_count > 1)
    {
      sem_overloads++;
      printf("  INFO SEMANTICO: propriedade '%s' usada com sobrecarga (%d perfis de tipo).\n",
             properties[i].property,
             rhs_type_count);
    }
  }
}

void semantic_print_report(void)
{
  printf("\n============================================================\n");
  printf("  Relatorio da Analise Semantica (Fase 3)\n");
  printf("============================================================\n");

  if (!root_scope)
  {
    printf("  AST semantica vazia.\n");
  }
  else
  {
    printf("\n  Arvore de escopos semanticos:\n");
    print_tree_rec(root_scope, 1);
  }

  printf("\n  Resumo semantico:\n");
  printf("    Classes declaradas:      %d\n", declared_class_count);
  printf("    Referencias de classe:   %d\n", class_ref_count);
  printf("    Propriedades analisadas: %d\n", property_count);
  printf("    Inferencias de contexto: %d\n", sem_inferences);
  printf("    Coercoes aplicadas:      %d\n", sem_coercions);
  printf("    Sobrecargas deduzidas:   %d\n", sem_overloads);
  printf("    Avisos semanticos:       %d\n", sem_warnings);
  printf("    Erros semanticos:        %d\n", sem_errors);
  printf("\n");
}

int semantic_error_count(void)
{
  return sem_errors;
}

int semantic_warning_count(void)
{
  return sem_warnings;
}
