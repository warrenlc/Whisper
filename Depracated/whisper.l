/* for token recognition */
%option noyywrap nodefault yylineno
%{
#include "whisper.h"
#include "whisper.tab.h"
%}
/* Exponents */
EXP       ([Ee][-+]?[0-9]+)

%%
"+" | 
"-" |
"*" |
"/" |
"@" |
"%" |
"=" |
"!" |     
"," |
";" |
"(" |
")"      { return yytext[0]; }
"{" |
"}"      { return yytext[0]; }
"->"     { return RUN; }
"?"      { return Q; }
"|"      { return BOR; } 
[\^]     { return BXOR; } 
"&"      { return BAND; }
"<<"     { return LSHIFT; }
">>"     { return RSHIFT; }
"~"      { return BNOT; }
">"      { yylval.fn = 1; return CMP; } /* comparison operators, all of which are a CMP token */
"<"      { yylval.fn = 2; return CMP; }
"!="     { yylval.fn = 3; return CMP; }  
"=="     { yylval.fn = 4; return CMP; }
">="     { yylval.fn = 5; return CMP; }
"<="     { yylval.fn = 6; return CMP; }
"||"     { return OR; }
"&&"     { return AND; } 
"true"   { yylval.b = 1; return BOOL; }
"false"  { yylval.b = 0; return BOOL; }
"if"     { return IF; } /* keywords -- to be expanded. Expand here, but then add */
"then"   { return THEN; } /* the necessary code to .y and .h files. */
"else"   { return ELSE; }
"while"  { return WHILE; }
"do"     { return DO; }
"let"    { return LET; }
"sqrt"   { yylval.fn = B_sqrt; return FUNC; } /* built in functions -- if expanded, be sure to check .h and .y files */
"exp"    { yylval.fn = B_exp; return FUNC; }
"log"    { yylval.fn = B_log; return FUNC; }
"print"  { yylval.fn = B_print; return FUNC; }
"quit"   { return QUIT; }
[a-zA-Z\_][\_a-zA-Z0-9]*   { yylval.s = symbol_lookup(yytext); return NAME; }  /* identifiers, i.e. names */
[0-9]+"."[0-9]*{EXP}? |
"."?[0-9]+{EXP}? { yylval.d = atof(yytext); return NUMBER; }

"//".*   /* Do nothing for comments */
\\\n { printf("<whisper>: "); } /* ignore line continuation */

\n       { return EOL; }
[ \t]    { /* Nothing */ }
.        { yyerror("Unknown character %c\n", *yytext); }
%%
