cmake_minimum_required(VERSION 3.5.0)
project(OWL2Lexer)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Encontra o Flex
find_package(FLEX REQUIRED)

# Gera o analisador léxico a partir da especificação Flex
FLEX_TARGET(OWLLexer src/owl_lexer.l ${CMAKE_CURRENT_BINARY_DIR}/lex.yy.c)

# Compila o executável
add_executable(owl_lexer ${FLEX_OWLLexer_OUTPUTS})