/* Whisper Grammar */ 
%{
#include <stdio.h>
#include <stdlib.h>
#include "whisper.h"
int yylex(); 
%}

%union {
  ast *a;
  double d;
  symbol *s;
  symbol_list *sl;
  int fn; /* which function */
  int b; /* boolean */
}

/* Tokens */
%token QUIT
%token <d> NUMBER
%token <s> NAME
%token <fn> FUNC
%token <b> BOOL
%token EOL
%token OR
%token AND
%token IF THEN ELSE WHILE DO LET
%token BNOT
%token INC
%token RUN
%token Q

%nonassoc <fn> CMP
%nonassoc '{' '}'
%right '=' /* This is how we assign associativity */
%left '+' '-'
%left '*' '/' '%' 
%right '@'
%left BOR
%left BXOR
%left BAND
%left RSHIFT LSHIFT
%right '~' BITWISE_NOT
%left OR
%left AND
%nonassoc '!' UMINUS

%type <a> exp stmt list explist
%type <sl> symlist

%start program
%%
program: %empty  /* Nothing */
 | program stmt EOL {
      printf("= %4.4g\n<whisper>: ", eval($2));
      tree_destroy($2); 
   }
 | program LET  NAME '(' symlist ')' '=' '{'  /* { symtab_push(); } */ list '}'  /* { symtab_pop(); } */ EOL 
                                 { function_define($3, $5, $9);
                                   printf("Function %s defined\n<whisper>: ", $3->name); }

 | program list EOL {
      printf("= %4.4g\n<whisper>: ", eval($2));
      tree_destroy($2);
 }

 | program QUIT { symtab_print(); symstack_destroy(); symtab_print(); printf("\nGoodbye!\n\n"); exit(0); } 
 
 | program error EOL { fprintf(stderr, "Syntax error @ line %d, check: %s\n", yylineno, yytext); exit(1); /* yyerrok; printf("got here!<whisper>: ") */  } 
; 

/* TODO: find out how to free allocated memory in the event of errors that cut parsing short 
     There is a built-in way to do this. -WC */


 stmt: IF exp THEN list { $$ = flow_create('I', $2, $4, NULL);  }
   | IF exp THEN list ELSE  list {  $$ = flow_create('I', $2, $4, $6); } 
   | WHILE exp DO /* { symtab_push(); } */ '{' list '}' { /* symtab_pop(); */ $$ = flow_create('W', $2, $5, NULL); }
   | exp
; 

list: /* nothing */  %empty { $$ = NULL; }
   | stmt ';' list { if ($3 == NULL)
                        $$ = $1;
                     else
                       $$ = ast_create('L', $1, $3);
                   }
;

exp: exp CMP  exp               { $$ = compare_create($2, $1, $3); }
   | exp '+'  exp               { $$ = ast_create('+', $1, $3); }
   | exp '-'  exp               { $$ = ast_create('-', $1, $3); }
   | exp '*'  exp               { $$ = ast_create('*', $1, $3); }
   | exp '/'  exp               { $$ = ast_create('/', $1, $3); }
   | exp '@'  exp               { $$ = ast_create('@', $1, $3); }
   | exp '%'  exp               { $$ = ast_create('%', $1, $3); }
   | exp BOR  exp               { $$ = ast_create('|', $1, $3); }
   | exp BXOR exp               { $$ = ast_create('^', $1, $3); }
   | exp BAND exp               { $$ = ast_create('&', $1, $3); }
   
   | exp RSHIFT exp             { $$ = ast_create('r', $1, $3); }
   | exp LSHIFT exp             { $$ = ast_create('l', $1, $3); }
   
   | BNOT exp %prec BITWISE_NOT { $$ = ast_create('~', $2, NULL); }
   | exp OR  exp                { $$ = ast_create('O', $1, $3); }
   | exp AND exp                { $$ = ast_create('A', $1, $3); }
   | '-' exp %prec UMINUS       { $$ = ast_create('M', $2, NULL); }
   | '!' exp %prec '!'          { $$ = ast_create('!', $2, NULL); }

   | '(' exp ')'                { $$ = $2; }
   | BOOL                       { $$ = boolean_create($1); }
   | NUMBER                     { $$ = number_create($1); }
   | FUNC '(' explist ')'       { $$ = function_create($1, $3); }
   | NAME                       { $$ = reference_create($1); }  
   | NAME '=' exp               { $$ = assign_create($1, $3); } 
   | NAME '(' explist ')'       { $$ = function_call_create($1, $3); }

;

explist: exp
 | exp ',' explist              { $$ = ast_create('L', $1, $3); }
;

symlist: /* nothing */           %empty { $$ = NULL; } /* Unsure of this still */
 | NAME                         { $$ = symbol_list_create($1, NULL); }
 | NAME ',' symlist             { $$ = symbol_list_create($1, $3); }
;

%%
