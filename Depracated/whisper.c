#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <math.h>

#include "whisper.h"

/* Symbol table, with a hash for lookup. 
 * the symbol will be a unique identifier 
 * to easily locate and retrieve what we need
 * from the symbol table. 
 * */
static unsigned
symbol_hash(char *sym) {
  /* the following operation will generate the hash for the given symbol, using
   * bitwise XOR operator (^) 
   */
  unsigned int hash = 0;
  unsigned c;
  while ((c = *sym++))
    hash = hash*9 ^ c;
  return hash;
}

void symtab_print() {
  int i;
  printf("Symbol stack: ");
  symtab_stack *stack_ptr = stack_top; 
  while (stack_ptr != NULL) {
    for (i = 0; i < NHASH; i++) {
        if (stack_ptr->symtab[i].name != NULL)
          printf("symbol name: %s, value: %.2f\n", stack_top->symtab[i].name, stack_top->symtab[i].value);
    }
    stack_ptr = stack_ptr->next;
  }
}

void symtab_push() {
  /* Add a symbol table (array of symbols) to the stack */
  printf("called symtable push.\n");
  symtab_stack *stack_new = (symtab_stack *)malloc(sizeof(symtab_stack));
  //printf("malloc'd new symtable in symtab_push @ %p\n", (void *)stack_new);

  stack_new->symtab = (symbol *)malloc(NHASH * sizeof(symbol));
  printf("malloc'd new symbol in symtab push.\n"); //'%s' in symtab_push @ %p\n", stack_new->symtab->name, (void *)stack_new->symtab);
  stack_new->size = 0;
  stack_new->next = stack_top;
  stack_top = stack_new;
}

void symtab_pop() {
  /* Remove the top symbol table from the stack */
  int i;
  if (stack_top->next == NULL || stack_top == NULL) return;
  symtab_stack *temp = stack_top;
  printf("popping the symtable.\n");
  for (i = 0; i < NHASH; i++) {
    if (stack_top->symtab[i].func) {
      printf("popping function: '%s' ", stack_top->symtab[i].name);
    }
  }
  if (temp != NULL) {
    stack_top = temp->next;
    symtab_free(temp->symtab);
    free(temp->symtab);
    free(temp);
  }
}

void symstack_destroy() {
  /* Free the allocated memory from the sack */
  symtab_stack *cur = stack_top;
  while (cur != NULL) {
    symtab_stack *temp = cur;
    cur = cur->next;
    free(temp);
  }
}

symbol*
symbol_lookup(char *sym) {
  /* Look through every 'level' of the stack for a symbol name 
   * If it is not found, create it. 
   * If it is a function name, look through the function table
   * */
  
  /* if the stack is empty, push a stack */
  if (stack_top == NULL)
    symtab_push();
  
  /* Start searchingn from the top of the stack */
  symtab_stack *stack_ptr = stack_top;
  while (stack_ptr != NULL) {
    symbol *sp = &stack_ptr->symtab[symbol_hash(sym) % NHASH];
    int symbol_count = NHASH;

    while (--symbol_count >= 0) {
      if (sp->name && !strcmp(sp->name, sym)) { 
        printf("\nmatched name '%s'\n", sp->name); 
        /* Symbol found that matches the name. Return pointer to the symbol */
        return sp;
      }
    
      if(!sp->name) {
        printf("did not match name '%s' in this scope.\n", sym);
        break;
      }
      if (++sp >= symtab + NHASH) 
        sp = stack_ptr->symtab; /* Don't wander off the symtable */
    }
    stack_ptr = stack_ptr->next;
  }
  /* If we are here, we didn't find the symbol in any scope. 
   * Make a new symbol in the current scope.
   */

  symbol *sym_new = &stack_top->symtab[symbol_hash(sym) % NHASH];
  int symbol_count = NHASH;
  while (--symbol_count >= 0) {
    if (!sym_new->name) {
      /* We use malloc and strcpy instead of strdup(). This makes it more clear
       * That we are allocating memory on the heap which needs to be freed later 
       */
      sym_new->name = malloc(strlen(sym) + 1);
      printf("new symbol name '%s' malloc'd at %p\n", sym, (void *)sym_new->name);
      strcpy(sym_new->name, sym);
      sym_new->value = 0;
      sym_new->func = NULL;
      sym_new->symbols = NULL;
      stack_top->size++;
      
      return sym_new;
    }
    /* Do not wander off the symtable */
    if (++sym_new >= stack_top->symtab + NHASH)
      sym_new = stack_top->symtab;
  }
  /* If all this failed ...*/
  yyerror("Symbol table overflow\n");
  abort();
}

ast*
ast_create(int nodetype, ast *l, ast *r) {
  /* Create a generic AST with the given nodetype
   * identifier and children, left & right 
   */
  ast *a = malloc(sizeof(ast));
  printf("\nast node with type %c malloc'd at %p\n", nodetype, (void *)a);

  if (!a) {
    yyerror("Could not allocate for ast_create().");
    exit(0);
  }
  a->nodetype = nodetype;
  a->left  = l;
  a->right = r;
  printf("from ast_create, nodetype is %c\n", nodetype);
  return a;
}

ast*
number_create(double d) {
  /* Create an AST node that to represent a number. Has no children */
  numval *a = malloc(sizeof(numval));
  printf("\nnumber with value %.2f malloc'd at %p\n", d, (void *)a);
  if (!a) {
    yyerror("Could not allocate for number_create().");
    exit(0);
  }
  a->nodetype = 'K';
  a->number = d;
  printf("\nCreated number Node, 'K' with value %.2f\n", a->number);
  return (ast *)a; 
}

ast*
boolean_create(int value) {
  /* Create a boolean node. Will have value either 1 for true or 0 for false */
  boolval *a = malloc(sizeof(boolval));
  printf("\nBool with value %d malloc'd at %p\n", value, (void *)a);
  if (!a) {
    yyerror("Could not allocate for boolean_create().");
    exit(0);
  }
  a->nodetype = 'B';
  a->value = value;
  printf("Made boolean node with value %d\n", a->value);
  return (ast *)a;
}

ast*
compare_create(int cmptype, ast *l, ast *r) {
  /* Create an AST node for comparison operations.
   * cmptype is a unique identifier for the given type
   * of comparison operation.
   */
  ast *a = malloc(sizeof(ast));
  printf("\nComparison Node with type %d malloc'd at %p\n", '0'+cmptype, (void *)a);
  if (!a) {
    yyerror("Could not allocate for compare_create().");
    exit(0);
  }  
  a->nodetype = '0' + cmptype;
  a->left  = l;
  a->right = r;
  printf("\nMade comparison Node with type %d\n", a->nodetype);
  return a;
}

ast*
function_create(int functype, ast *l) {
  /* Create a node to represent a call to a built-in C function with a given
   * functype (see .H file enum built_in_functions ) and left child
   * containing function body.
   */
  function_call *a = malloc(sizeof(function_call));
  printf("\nBuilt in function node with type %d malloc'd at %p\n", functype, (void *)a);
  if (!a) {
    yyerror("Could not allocate for function_create().");
    exit(0);
  }
  a->nodetype = 'F';
  a->left  = l;
  a->functype = functype;
  printf("Made built in function node\n");
  return (ast *)a; 
}

ast*
function_call_create(symbol *s, ast *l) {
  /* Create an AST node for a user-designed function call.
   * symbol *s matches the name of the function and a pointer to the
   * function body itself and left child the arguments
   */
  u_function_call *a = malloc(sizeof(u_function_call));
  printf("\nUser function node with name %s malloc'd at %p\n", s->name, (void *)a);
  if (!a) {
    yyerror("Could not allocate for function_call_create().");
    exit(0);
  }
  a->nodetype = 'C';
  a->left = l;
  a->symbol = s;
  printf("\nMade user defined function Node. "
        "Left has type %c with symbol name %s "
        "that points to function node with type %c\n", 
        a->left->nodetype, a->symbol->name, a->symbol->func->nodetype);
  return (ast *)a;
}

ast*
reference_create(symbol *s) {
  /* Creates an AST node representing a variable name */
  symbol_ref *a = malloc(sizeof(symbol_ref));
  printf("\nReference node with name '%s' malloc'd at %p\n", s->name, (void *)a);
  if (!a) {
    yyerror("Could not allocate for reference_create().");
    exit(0);
  }
  a->nodetype = 'N';
  a->symbol = s;
  printf("\nMade reference Node 'N' with reference to %s\n", a->symbol->name);
  return (ast *)a;
}

ast*
assign_create(symbol *s, ast *v) {
  /* Creates an AST Node representing an assignment operation.
   * The symbol represents the variable to be assigned, v is the
   * AST node that represents the expression which is a child
   * of this node with '=' nodetype 
   * */
  symbol_assign *a = malloc(sizeof(symbol_assign));
  printf("\nAssignment node with name '%s' and value node type %c malloc'd at %p\n", s->name, v->nodetype, (void *)a);
  if (!a) {
    yyerror("Could not allocate for assign_create().");
    exit(0);
  }
  a->nodetype = '=';
  a->symbol = s;
  a->value = v;
  printf("\nAssignment node created, type '=' with symbol name %s whose value as type %c\n", a->symbol->name, a->value->nodetype);
  return (ast *)a;
}

ast*
flow_create(int nodetype, ast *cond, ast *th, ast *el) {
  /* Creates an AST for flow, such as if/then if/then/else or
   * while. 
   * Node type is determined based on if it is a while loop
   * or if-statement, cond is a child node that is the condition
   * that must execute, th and el represent 'then' and 'else'
   * children nodes to be executed.
   */
  flow *a = malloc(sizeof(flow));
  printf("\nFlow node with type %c malloc'd at %p\n", nodetype, (void *)a);
  if (!a) {
    yyerror("Could not allocate for flow_create().");
    exit(0);
  }
  a->nodetype = nodetype;
  a->condition = cond;
  a->do_list = th;
  a->else_branch = el;
  printf("\nflow node created with type %c" 
        "whose condition has type %c, do-list type: %d\n", 
        a->nodetype, a->condition->nodetype, a->do_list->nodetype);
  return (ast *)a;
}

void 
tree_destroy(ast *a) {
  /* Given an AST, traverse the nodes (depth first) and free all nodes */
  switch(a->nodetype) {
    /* two subtrees */
    case '+':
    case '-':
    case '*':
    case '/':
    case '@':
    case '^':
    case 'l':
    case 'r':
    case '%':
    case '|':
    case '&':
    case 'O':
    case 'A':
    /* comparison operators */
    case '1': case '2': case '3': case '4': case '5': case '6':
    case 'L':
      tree_destroy(a->right);

      /* one subtree */
    case 'C': case 'F': case '!': case '~': case 'V': case 'M':
      tree_destroy(a->left);
    
      /* no subtrees */
    case 'K': case 'N': case 'B':
      break;
   
    case '=':
      tree_destroy(((symbol_assign *)a)->value);
      
      break;

    /* up to three subtrees */
    case 'I': case 'W':
      tree_destroy( ((flow *)a)->condition );
      if ( ((flow *)a)->do_list) tree_destroy( ((flow *)a)->do_list);
      if ( ((flow *)a)->else_branch) tree_destroy( ((flow *)a)->else_branch);
      break;
    default: printf("Internal Error while freeing bad node %c\n", a->nodetype);
    }
  printf("\nFreeing the base node with type %c\n", a->nodetype);
  free(a);
}

symbol_list*
symbol_list_create(symbol *sym, symbol_list *next) {
  /* Create an argument list for function calls */
  symbol_list *sl = malloc(sizeof(symbol_list));
  printf("\nSymbol list node with name %s malloc'd at %p\n", sym->name, (void *)sl);
  if (!sl) {
    yyerror("Could not allocate for symbol_list_create().");
    exit(0);
  }
  sl->symbol = sym;
  sl->next = next;
  printf("\nCreated a symbol list, with name %s\n", sl->symbol->name);
  return sl;
}

void
symbol_list_free(symbol_list *sl) {
  /* Free the given symbol list */
  printf("\nCalled symbol_list_free(). First symbol: %s\n", sl->symbol->name);
  symbol_list *temp_sl;
  while (sl) {
    temp_sl = sl->next;
    printf("\nFree-ing %s\n", sl->symbol->name);
    free(sl);
    sl = temp_sl;
  }
}

static double call_builtin_fun(function_call *);
static double call_user_fun(u_function_call *);

double
eval(ast *a) {
  /* Given an AST node, evaluate the node and all its children. */
  double v = 0.0;
  printf("%c\n", a->nodetype); 
  if (!a) {
    yyerror("error during ast eval().");
    return 0.0;
  }  

  switch(a->nodetype) {
  
    /* Boolean values */
    case 'B' : v = ((boolval *)a)->value; break;
      /* Numerical constants */
    case 'K' : v = ((numval *)a)->number; break;
      /* identifier names */
    case 'N' : v = ((symbol_ref *)a)->symbol->value; break;
      /* Assignment */
    case '=' : printf("Evaluating assignment node '='\n"); 
              v = ((symbol_assign *)a)->symbol->value = eval(((symbol_assign *)a)->value); 
              break;
      /* Expressions */
    case '+' : v = eval(a->left)  +   eval(a->right); break;
    case '-' : v = eval(a->left)  -   eval(a->right); break;
    case '*' : v = eval(a->left)  *   eval(a->right); break;
    case '/' : v = eval(a->left)  /   eval(a->right); break;
    case '@' : v = pow(eval(a->left), eval(a->right)); break;

    case '^' : v = (int)eval(a->left)  ^  (int)eval(a->right); break;
    case 'l' : v = (int)eval(a->left)  << (int)eval(a->right); break;
    case 'r' : v = (int)eval(a->left)  >> (int)eval(a->right); break;
    case '%' : v = (int)eval(a->left)  %  (int)eval(a->right); break;
    case '|' : v = (int)eval(a->left)  |  (int)eval(a->right); break;
    case '&' : v = (int)eval(a->left)  &  (int)eval(a->right); break;
    case 'O' : v = (int)eval(a->left)  || (int)eval(a->right); break;
    case 'A' : v = (int)eval(a->left)  && (int)eval(a->right); break;
    
    case '!' : v = !(int)eval(a->left); break;
    case '~' : v = ~(int)eval(a->left); break;
    case 'M' : v = (-1)* eval(a->left); break;
    
      /* comparisons */
    case '1' : v = (eval(a->left) >  eval(a->right)) ? 1 : 0; break;
    case '2' : v = (eval(a->left) <  eval(a->right)) ? 1 : 0; break;
    case '3' : v = (eval(a->left) != eval(a->right)) ? 1 : 0; break;
    case '4' : v = (eval(a->left) == eval(a->right)) ? 1 : 0; break;
    case '5' : v = (eval(a->left) >= eval(a->right)) ? 1 : 0; break;
    case '6' : v = (eval(a->left) <= eval(a->right)) ? 1 : 0; break;
    
    /* Flow */
    case 'I': /* If-statement */
      if (eval( ((flow *)a)->condition) != 0) {
        if ( ((flow *)a)->do_list) {
          v = eval( ((flow *)a)->do_list); 
        } else
          v = 0.0;
      } else {
        if ( ((flow *)a)->else_branch) {
          v = eval(((flow *)a)->else_branch);
        } else {
          v = 0.0;
        }
      }
      break;

    case 'W': /* While loop */
      v = 0.0;
      if ( ((flow *)a)->do_list) {
        while (eval(((flow *)a)->condition) != 0)
          v = eval(((flow *)a)->do_list);
      }
      break;
    
    case 'L': eval(a->left); v = eval(a->right); break; /* Expression list or statement list */
    case 'F': v = call_builtin_fun((function_call *)a); break; /* built-in function call */
    case 'C': v = call_user_fun((u_function_call *)a);  break; /* user-defined function call */
    case 'V': v = eval(a->left); break;  /* variable_evaluate((variable *) a); break; */

    default: printf("Internal Error. bad node %c\n", a->nodetype);
  }
  return v;
}

static double call_builtin_fun(function_call *f) {
  /* Evaluate the given built-in function node. Called from double eval(ast *a)*/
  enum built_in_functions functype = f->functype;
  double v = eval(f->left);

  switch(functype) {
    case B_sqrt:
      return sqrt(v);
    case B_exp:
      return exp(v);
    case B_log:
      return log(v);
    case B_print:
      printf("=%4.4g\n", v);
      return v;
    default:
      yyerror("Could not match function %d.", functype);
      return 0.0;
  }
}

void
function_define(symbol *name, symbol_list *syms, ast *function) {
  /* Define a function with the given values sent from the parser. 
   */
  /* Create a new symbol table for this function's scope */
  /*  symtab_push();  */
  if (name->symbols) symbol_list_free(name->symbols);
  if (name->func) tree_destroy(name->func);
  name->symbols = syms;
  name->func = function;
  printf("Called function_define()\n");
}

static double call_user_fun(u_function_call *f) {
  /* Evaluate a user-defined function. 
   */
  /* How this works: 
   * Evaluate the actual arguments given in the call to the function
   * Save the current value of the placeholder 'dummy' arguments, assign
   * the evaluated values to those arguments.
   * Evaluate the body of the function which now uses the actual
   * values calculated in the first step.
   * Put the 'dummy values' back
   * Return the value of the expression
   */
  printf("Called call_user_fun()\n");
  symbol *fn = f->symbol;
  symbol_list *sl;
  ast *args = f->left;
  double *old, *new;
  double v;
  int num_args;
  int i;

  if (!fn->func) {
    yyerror("function %s undefined.", fn->name);
    return 0;
  }

/* Count the number of arguments by iterating over the argument list (symbol list) */
  sl = fn->symbols;
  for (num_args = 0; sl; sl = sl->next) 
    num_args++;

/* Allocate for array to hold the 'old' values, i.e. the values in the symbol list already */
  old = (double *)malloc(num_args * sizeof(double)); 
  printf("malloc'd array for saving old symbol list for function '%s' @ %p\n", f->symbol->name, (void *)old);
/* Allocate for array to hold the 'new values', i.e. that which we will calculate */
  new = (double *)malloc(num_args * sizeof(double));
  printf("malloc'd array for saving new symbol list for function '%s' @ %p\n", f->symbol->name, (void *)new);
  
  if (!old || !new) {
    yyerror("Could not allocate space in %s", fn->name);
    return 0.0;
  }

  /* Evaluate the arguments */
  for(i = 0; i < num_args; i++) {
    if(!args) {
      yyerror("too few args in call to %s", fn->name);
      free(old);
      free(new);
      return 0.0;
    }

    if (args->nodetype == 'L') { /* If we get to a list node */
      new[i] = eval(args->left);
      args = args->right;
    } else {
      new[i] = eval(args);
      args = NULL;
    }
  }

  /* Save old values and assign new ones */
  sl = fn->symbols;
  for (i = 0; i < num_args; i++) {
    symbol *s = sl->symbol;
    old[i] = s->value;
    s->value = new[i];
    sl = sl->next;
  }

  free(new);

  /* Evaluate the function */
  v = eval(fn->func);

  /* Put the real values back where they were */
  sl = fn->symbols;
  for(i = 0; i < num_args; i++) {
    symbol *s = sl->symbol;
    s->value = old[i];
    sl = sl->next;
  }  

  free(old);
  return v;
}

void symtab_free(symbol table[]) {
  printf("called symtab free\n");
  for (int i = 0; i < NHASH; i++) {
    if (table[i].name != NULL)
      free(table[i].name);
  }
}

void
yyerror(char *s, ...) {
  /* Print syntax error information
   * to stderr.
   */
  va_list ap;
  va_start(ap, s); 
  fprintf(stderr, "line number %d: %s at '%s'\n", yylineno, s, yytext);
}

int main(int argc, char* argv[]) {
  printf("<whisper>: ");
  yyparse();
  return 0;
}
