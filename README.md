# Analisador Léxico - OWL2 Manchester Syntax

**Disciplina:** Compiladores - UFERSA  
**Ferramenta:** Flex (gerador de analisadores léxicos)

## Sobre o Projeto

Este projeto implementa um **analisador léxico** para a linguagem OWL2 no formato Manchester Syntax.
O analisador lê um arquivo `.owl` contendo descrições de ontologias e identifica todos os **tokens**
da linguagem, registrando-os em uma **tabela de símbolos**.

---

## Estrutura do Projeto

```
src/
├── owl_lexer.l       → Regras Flex (padrões de reconhecimento de tokens)
├── token.h           → Definição dos tipos de token (enum + struct)
├── token.c           → Mapeamento de cada token para seu nome legível
├── symbol_table.h    → Interface da tabela de símbolos
├── symbol_table.c    → Implementação da tabela de símbolos
└── main.c            → Ponto de entrada do programa

test/
├── pizza_ontology.owl      → Teste principal (ontologia de pizzas)
├── animal_ontology.owl     → Teste com ontologia de animais
├── vehicle_ontology.owl    → Teste com ontologia de veículos
└── university_ontology.owl → Teste com ontologia de universidade

Makefile              → Sistema de build
```

---

## Tokens Reconhecidos

| Categoria                       | Tokens                                                                                                     | Exemplos                   |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------- | -------------------------- |
| Palavras-chave OWL              | `CLASS`, `EQUIVALENT_TO`, `SUBCLASS_OF`, `INDIVIDUALS`, `DISJOINT_CLASSES`                                 | `Class:`, `EquivalentTo:`  |
| Palavras reservadas             | `SOME`, `ALL`, `ONLY`, `VALUE`, `MIN`, `MAX`, `EXACTLY`, `THAT`, `NOT`, `AND`, `OR`                        | `some`, `and`, `or`        |
| Identificadores de classes      | `CLASS_ID`                                                                                                 | `Pizza`, `VegetarianPizza` |
| Identificadores de propriedades | `PROPERTY_ID`                                                                                              | `hasTopping`, `ssn`        |
| Nomes de indivíduos             | `INDIVIDUAL_ID`                                                                                            | `Customer1`, `Waiter2`     |
| Namespace + Tipo de dado        | `NAMESPACE_ID`, `DATA_TYPE`                                                                                | `xsd:` + `integer`         |
| Cardinalidades                  | `INTEGER`                                                                                                  | `1`, `3`, `400`            |
| Símbolos especiais              | `LBRACKET`, `RBRACKET`, `LBRACE`, `RBRACE`, `LPAREN`, `RPAREN`, `GTE`, `LTE`, `GT`, `LT`, `QUOTE`, `COMMA` | `[`, `>=`, `(`             |

---

## Decisões de Design

### Estado Flex para Namespaces

O reconhecimento de `xsd:integer` usa um **estado exclusivo** (`%x DATATYPE`).
Ao encontrar `xsd:`, o lexer emite `NAMESPACE_ID` e entra no estado `DATATYPE`, onde a próxima
palavra é reconhecida como `DATA_TYPE`. Isso evita que `integer` seja confundido com um
identificador de propriedade.

### Prioridade de regras (longest match + first match)

- `Customer1` é reconhecido como `INDIVIDUAL_ID` (e não `CLASS_ID` + `INTEGER`) porque
  o Flex aplica **longest match**.
- Palavras reservadas como `some` e `and` são listadas **antes** de `PROPERTY_ID`,
  garantindo prioridade por **first match**.

### Tabela de símbolos

Lista sequencial de todos os tokens reconhecidos (lexema, tipo e linha).
Sem escopo — isso seria responsabilidade do parser/análise semântica.

---

## Como Executar em Linux

### 1. Instalar dependências

No **Ubuntu/Debian**:

```bash
sudo apt update
sudo apt install flex gcc make
```

No **Fedora**:

```bash
sudo dnf install flex gcc make
```

No **Arch Linux**:

```bash
sudo pacman -S flex gcc make
```

### 2. Clonar o projeto

```bash
git clone <url-do-repositorio>
cd first-unit-project
```

### 3. Compilar

```bash
make
```

Esse comando executa duas etapas:

1. `flex -o src/lex.yy.c src/owl_lexer.l` — Flex lê o arquivo `.l` e gera um scanner em C
2. `gcc` compila todos os módulos (`main.c`, `token.c`, `symbol_table.c`, `lex.yy.c`) no executável `owl_lexer`

### 4. Executar com o arquivo de teste

```bash
make test
```

Ou diretamente:

```bash
./owl_lexer test/pizza_ontology.owl
```

### 5. Executar com outros arquivos de teste

```bash
./owl_lexer test/animal_ontology.owl
./owl_lexer test/vehicle_ontology.owl
./owl_lexer test/university_ontology.owl
```

Ou com qualquer arquivo `.owl`:

```bash
./owl_lexer caminho/do/seu/arquivo.owl
```

### 6. Executar com entrada pelo teclado (stdin)

```bash
./owl_lexer
```

Digite o código OWL e pressione **Ctrl+D** para finalizar.

### 7. Limpar arquivos gerados

```bash
make clean
```

Remove o executável `owl_lexer` e o arquivo gerado `src/lex.yy.c`.

---

## Exemplo de Saída

Para a entrada:

```
Class: Customer
EquivalentTo:
    Person
    and (hasPhone some xsd:string)
```

A saída será:

```
  LINHA  TOKEN                   LEXEMA
  -----  ----------------------  ----------------------------
  1      CLASS                   Class:
  1      CLASS_ID                Customer
  2      EQUIVALENT_TO           EquivalentTo:
  3      CLASS_ID                Person
  4      AND                     and
  4      LPAREN                  (
  4      PROPERTY_ID             hasPhone
  4      SOME                    some
  4      NAMESPACE_ID            xsd:
  4      DATA_TYPE               string
  4      RPAREN                  )
```

Ao final, é impressa a **tabela de símbolos** com todos os tokens reconhecidos.
