%{
// scanner.l -- our assembler input scanning program

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "parser.h"

extern YYSTYPE yylval;

#include "yfasm.h"

%}

%option noyywrap

delim         [ \t]
whitesp       {delim}+
digit         [0-9]
alpha         [a-zA-Z]
alphanum      [a-zA-Z0-9]
number        [-]?{digit}*[.]?{digit}+
integer       [-]?{digit}+
hex	      "0x"[0-9a-fA-F]+
string        \"[^\"]*\"
register      [rR][-]?{digit}+
comment       "#"[^\n]*
identifier    {alphanum}[a-zA-Z0-9_]*

%%

{register}   { sscanf(yytext+1, "%d", &yylval); return REG; }
{integer}    { sscanf(yytext, "%d", &yylval); return INTEGER; }
{hex}        { sscanf(yytext+2, "%x", &yylval); return INTEGER; }

"\n"        { return NEWLINE; }
","	    { return COMMA; }
":"	    { return COLON; }

"NOP"       { return NOP; }
"LRI"	    { return LRI; }
"ADD"       { return ADD; }
"SUB"       { return SUB; }
"OR"        { return OR; }
"XOR"       { return XOR; }
"HALT"      { return HALT; }
"BRA"       { return BRA; }
"BRANZ"     { return BRANZ; }
"BRAL"      { return BRAL; }
"BRALNZ"    { return BRALNZ; }
"CALL"       { return CALL; }

".imem"	    { return sIMEM; }
".regfile"  { return sREGFILE; }
".base"     { return sBASE; }
".define"   { return sDEFINE; }
".register" { return sREGISTER; }
".end"       { return END; }

{identifier} { 
		yylval = yf_getsymbol(yytext); 
		if(yylval<=0) 
			yylval = yf_addsymbol(yytext, ST_UNKNOWN, 0); 
		return IDENTIFIER; 
	     }
{string}    {
		yytext[strlen(yytext)-1] = 0;
		yylval = yf_addstring(&yytext[1]);
		return STRING;
	    }

{whitesp}   { /* No action and no return */ }
{comment}   { /* No action and no return */ }

