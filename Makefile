# ==========================================================================
# Makefile - Analisador Sintático OWL2 Manchester Syntax
# Disciplina: Compiladores - UFERSA
#
# Pipeline: Bison → Flex → GCC
#   bison -d src/owl_parser.y  → src/owl_parser.tab.c + src/owl_parser.tab.h
#   flex src/owl_lexer.l       → src/lex.yy.c
#   gcc src/*.c                → owl_parser
# ==========================================================================

CC     = gcc
LEX    = flex
BISON  = bison
CFLAGS = -Wall -I$(SRC_DIR)

# Diretórios
SRC_DIR  = src
TEST_DIR = test

# Arquivos fonte
BISON_SRC    = $(SRC_DIR)/owl_parser.y
BISON_OUTPUT = $(SRC_DIR)/owl_parser.tab.c
BISON_HEADER = $(SRC_DIR)/owl_parser.tab.h
LEX_SRC      = $(SRC_DIR)/owl_lexer.l
LEX_OUTPUT   = $(SRC_DIR)/lex.yy.c
SOURCES      = $(SRC_DIR)/main.c $(SRC_DIR)/token.c $(SRC_DIR)/symbol_table.c $(BISON_OUTPUT) $(LEX_OUTPUT)
TARGET       = owl_parser
TEST_FILE    = $(TEST_DIR)/pizza_ontology.owl

# ---------- Regras ----------

all: $(TARGET)

# Compila o executável a partir de todos os módulos
$(TARGET): $(SOURCES)
	$(CC) $(CFLAGS) $(SOURCES) -o $(TARGET)

# Gera o parser C e o header de tokens a partir da especificação Bison
$(BISON_OUTPUT) $(BISON_HEADER): $(BISON_SRC)
	$(BISON) -d $(BISON_SRC) -o $(BISON_OUTPUT)

# Gera o scanner C a partir da especificação Flex (depende do header Bison)
$(LEX_OUTPUT): $(LEX_SRC) $(BISON_HEADER)
	$(LEX) -o $(LEX_OUTPUT) $(LEX_SRC)

# Executa o analisador com o arquivo de teste
test: $(TARGET)
	./$(TARGET) $(TEST_FILE)

# Executa o analisador com todos os arquivos de teste
test-all: $(TARGET)
	@for f in $(TEST_DIR)/*.owl; do \
		echo "\n========== $$f =========="; \
		./$(TARGET) $$f; \
	done

# Remove arquivos gerados
clean:
	rm -f $(TARGET) $(LEX_OUTPUT) $(BISON_OUTPUT) $(BISON_HEADER)

.PHONY: all test test-all clean
