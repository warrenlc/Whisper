/*
 * Declarations for Whisper
 * */
#ifndef WHISPER_H 
#define WHISPER_H 
int yyparse();

/* Macros */
#define INPUT_SIZE 1024
#define MAX_SCOPE_DEPTH 100

/* symbol table of fixed size */
#define NHASH  100/* 9997 */

/* Interface for our lexer */
extern int yylineno;        
extern char *yytext;
void yyerror(char *s, ...); /* We want to handle a variable
                             * number of arguments */

/* Symbols and Scope */
typedef struct symbol {
  char *name;  /* variable name */
  double value;
  struct ast *func; /* function statement */
  struct symbol_list *symbols; /* argument list */
}symbol;

static symbol symtab[NHASH]; 

typedef struct symtab_stack {
  symbol *symtab;
  size_t size;
  struct symtab_stack *next;
}symtab_stack;

static symtab_stack *stack_top = NULL;
void symtab_push(); 
void symtab_pop();
void symstack_destroy();

symbol* symbol_lookup(char *);
void symtab_print();

typedef struct symbol_list {
  struct symbol *symbol;
  struct symbol_list *next;
}symbol_list;

symbol_list *symbol_list_create(symbol *sym, symbol_list *next);
void symbol_list_free(symbol_list *sl);

/* END SYMBOLS AND SCOPE */

/* Function Hashing / Storage */
static symbol functab[NHASH];


/* AST NODES ***
 * types of nodes 
 * binary operations: + - * / @ % | ^ & r l O A 
 * unary operations: ! M ~
 * 0-7 comparison ops, bit coded 04 equal, 02 less, 01 greater
 * L expression or statement list
 * I if statement
 * W while statement
 * N symbol reference
 * = assignment
 * S list of symbols
 * F built in function call
 * C user-defined function call
 * */

typedef enum built_in_functions {
  B_sqrt = 1,
  B_exp,
  B_log,
  B_print
}built_in_functions;

/* Nodes for the Abstract Syntax Tree */
typedef struct ast {
  int nodetype;
  struct ast *left;
  struct ast *right;
}ast;

typedef struct function_call { /* built in function, type F */
  int nodetype;
  struct ast *left;
  enum built_in_functions functype;
}function_call;

typedef struct u_function_call { /* user-defined function, type C*/
  int nodetype;
  struct ast *left;
  struct symbol *symbol;
}u_function_call; 

typedef struct flow {
  int nodetype; /* I or W (if or while) */
  struct ast *condition;
  struct ast *do_list;
  struct ast *else_branch;
}flow;

typedef struct numval {
  int nodetype; /* type K */
  double number;
}numval;

typedef struct boolval {
  int nodetype; /* type B */
  int value;
}boolval;

typedef struct symbol_ref {
  int nodetype;   /* Type N */
  struct symbol *symbol;
}symbol_ref;

typedef struct symbol_assign{
  int nodetype;   /* type = */
  struct symbol *symbol;
  struct ast *value;
}symbol_assign;

/* AST FUNCTIONS */
/* Make our abstract syntax tree */
ast *ast_create(int nodetype, ast *left, ast *right);
ast *boolean_create(int value);
ast *number_create(double d);
ast *compare_create(int cmptype, ast *left, ast *right);
ast *function_create(int functype, ast *left);
ast *function_call_create(symbol *s, ast *left);
ast *reference_create(symbol *s);
ast *assign_create(symbol *s, ast *value); 
ast *flow_create(int nodetype, ast *condition, ast *then_, ast *else_);

/* Print a symbol table */
void symbol_table_print(symbol_list *sl);

/* Free a symbol table */
void symtab_free(symbol symtab[]);

/* define a function  or variable */
void function_define(symbol *name, symbol_list *syms, ast *statements);

/* Evaluate the ast */
double eval(ast *);

/* free and destroy the ast */
void tree_destroy(ast *);

#endif /* WHISPER_H */
