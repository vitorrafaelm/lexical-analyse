# ==========================================================================
# Makefile - Analisador Léxico OWL2 Manchester Syntax
# Disciplina: Compiladores - UFERSA
# ==========================================================================

CC     = gcc
LEX    = flex
CFLAGS = -Wall -I$(SRC_DIR)

# Diretórios
SRC_DIR  = src
TEST_DIR = test

# Arquivos fonte
LEX_SRC    = $(SRC_DIR)/owl_lexer.l
LEX_OUTPUT = $(SRC_DIR)/lex.yy.c
SOURCES    = $(SRC_DIR)/main.c $(SRC_DIR)/token.c $(SRC_DIR)/symbol_table.c $(LEX_OUTPUT)
TARGET     = owl_lexer
TEST_FILE  = $(TEST_DIR)/pizza_ontology.owl

# ---------- Regras ----------

all: $(TARGET)

# Compila o executável a partir de todos os módulos
$(TARGET): $(SOURCES)
	$(CC) $(CFLAGS) $(SOURCES) -o $(TARGET)

# Gera o código C a partir da especificação Flex
$(LEX_OUTPUT): $(LEX_SRC)
	$(LEX) -o $(LEX_OUTPUT) $(LEX_SRC)

# Executa o analisador com o arquivo de teste
test: $(TARGET)
	./$(TARGET) $(TEST_FILE)

# Remove arquivos gerados
clean:
	rm -f $(TARGET) $(LEX_OUTPUT)

.PHONY: all test clean
