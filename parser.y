/* parser.y - parser for YourFirstCPU assembler */
%{
#define YYSTYPE long      /* yyparse() stack type */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "yfasm.h"
#include "yfsys.h"

/* global variables
*/

/* our system info struct holds the parameters of our cpu */
yf_sysinfo sys = { 
	DEF_IMEM, 
	DEF_IMEM_WIDTH,
	DEF_REGFILE, 
	DEF_OPCODE_WIDTH, 
	DEF_REG_ADDR_WIDTH, 
	DEF_BASE
	};

/* the symbol table holds identifiers found in the source file and thier value */
yf_symbols symbol_table;

/* strings are passed from the scanner to the parser in this string table */
yf_strings string_table;

/* our assembler instruction memory */
unsigned long* lpimem = NULL;

/* holds the highest code address */
unsigned long codesize = 0;

%}

/* standard tokens */
%token NEWLINE COMMA COLON REG IDENTIFIER INTEGER STRING FLOAT END

/* assembler directives */
%token sIMEM sREGFILE sBASE sREGISTER sDEFINE 

/* cpu mnemonic tokens */
%token NOP LRI ADD SUB OR XOR HALT BRA BRANZ BRAL BRALNZ CALL


/* our assembler grammer 
*/
%%
input:              /* empty string */
     | input line { yylineno++; }
     ;
line: NEWLINE
    | statement NEWLINE
    | asm_expr NEWLINE
    | label_decl NEWLINE
    | register_decl NEWLINE
    | definition NEWLINE
    | END
    ;

/* assembler directives */
asm_expr: sIMEM INTEGER	{ alloc_imem( $2 ); }
	| sIMEM INTEGER INTEGER { sys.imem_width = $3; alloc_imem( $2 ); }
        | sREGFILE INTEGER INTEGER { sys.regfile = $2; sys.reg_addr_bits = $3; }
        | sREGFILE INTEGER { sys.regfile = $2; }
	| sBASE INTEGER { sys.base = $2; }
	;

/* grammers for each cpu mnemonic */
statement: NOP { gen( xNOP, 0); }
         | LRI format_rd_imm   { gen( xLRI, $2); }
         | ADD format_ra_rb_rd { gen( xADD, $2 ); }
	 | SUB format_ra_rb_rd { gen( xSUB, $2 ); }
	 | OR format_ra_rb_rd { gen( xOR, $2 ); }
	 | XOR format_ra_rb_rd { gen( xXOR, $2 ); }
	 | BRA format_0_rb_0 { gen( xBRA, $2 ); }
	 | BRANZ format_ra_rb_0 { gen( xBRANZ, $2 ); }
	 | BRAL format_0_label { gen( xBRAL, $2 ); }
	 | BRALNZ format_label_ra { gen( xBRALNZ, $2 ); }
	 | CALL format_label_rd { gen( xCALL, $2 ); }
	 | HALT { gen( xHALT, 0xfff ); }
	 ;

/* grammers for each of the mnemonic formats */
format_rd_imm: reg COMMA INTEGER { $$ = ENCR( ($3 >> sys.reg_addr_bits) & 0xf, $3 & 0xf, $1 ); };
format_ra_rb_rd: reg COMMA reg COMMA reg { $$ = ENCR( $1, $3, $5 ); };
format_0_rb_0: reg { $$ = ENCR( 0, $1, 0 ); };
format_ra_rb_0: reg COMMA reg { $$ = ENCR($1, $2, 0); };
format_label_ra: label COMMA reg { $$ = ENCR($3, $1 & 0xf, ($1 >> sys.reg_addr_bits)&0xf ); };
format_label_rd: label COMMA reg { $$ = ENCR( ($1 >> sys.reg_addr_bits)&0xf, $1 & 0xf, $3 ); };
format_0_label: label { $$ = ENCR(0, $1 & 0xf, ($1 >> sys.reg_addr_bits)&0xf ); };
//format_0_rb_rd: reg COMMA reg { $$ = ENC( 0, $1, $3 ); };
//format_ra_imm: reg COMMA INTEGER { $$ = ENCR($1, $3 & 0xf, ($3 >> sys.reg_addr_bits)&0xf ); };
//format_imm_0: INTEGER { $$ = ENCR(0, $1, 0); };

label_decl: IDENTIFIER COLON { yf_setsymbol( $1, ST_LABEL, sys.base); };
register_decl: sREGISTER REG IDENTIFIER { yf_setsymbol( $3, ST_REGISTER, $2); };
definition: sDEFINE IDENTIFIER INTEGER { yf_setsymbol( $2, ST_INT, $3); }
	  | sDEFINE IDENTIFIER STRING { yf_setsymbol( $2, ST_STRING, $3); }
	  ;

/* a label is a reference to a memory address, a constant is also valid */
label: INTEGER { $$ = $1; }
     | IDENTIFIER { yf_symbol s = yf_getsymbol($1); if(s.type==ST_LABEL) $$ = s.lvalue; else yyerror("expected label"); }

/* a reg is a reference to a register */
reg: REG { $$ = $1; }
   | IDENTIFIER { yf_symbol s = yf_getsymbol($1); if(s.type==ST_REGISTER) $$ = s.lvalue; else yyerror("expected register"); }

%%

/* yacc uses this function to report an error */
int yyerror(const char* err) 
{
	printf("%s on line %d : %s\n", err, yylineno, yytext);
}

/* allocates our instrunction memory that we will assemble to */
void alloc_imem( unsigned long newsize ) 
{
	if( !lpimem || (newsize != sys.imem) ) {
		if(lpimem) {
			lpimem = (unsigned long*)realloc( lpimem, newsize * sizeof(unsigned long) );
			memset( lpimem + sys.imem, 0xff, newsize * sizeof(unsigned long) - sys.imem );
		} else {
			lpimem = (unsigned long*)malloc( newsize * sizeof(unsigned long) );
			memset( lpimem, 0xff, newsize * sizeof(unsigned long) );
		}
		sys.imem = newsize;
	}
}

int yf_getsymbol(string name)
{
	int i = 0;
	for(yf_symbols::const_iterator s=symbol_table.begin(), _s=symbol_table.end(); s!=_s; s++,i++)
		if( s->name == name)
			return i;
	return -1;
}

yf_symbol yf_getsymbol(int i) 
{ 
	if(i<symbol_table.size()) 
		return symbol_table[i]; 
	else { 
		yyerror("symbol ordinal out of range."); 
		exit(-1); 
	} 
}
int yf_addsymbol(string name, yf_symboltype type, long value)
{
	yf_symbol si;
	si.name = name;
	si.type = type;
	si.lvalue = value;
	symbol_table.insert(symbol_table.end(), si);
	return symbol_table.size()-1;
}

int yf_addsymbol(string name, yf_symboltype type, string value)
{
	yf_symbol si;
	si.name = name;
	si.type = type;
	si.lvalue = yf_addstring(value);
	symbol_table.insert(symbol_table.end(), si);
	return symbol_table.size()-1;
}

yf_symbol* yf_setsymbol(int i, yf_symboltype type, long value)
{
	if(i>=symbol_table.size())
		return NULL;
	yf_symbol* s = &symbol_table[i];
	s->type = type;
	s->lvalue = value;
	//printf("SYMBOL(#%d, n:'%s', t:%d, v:%d)\n", i, s->name.c_str(), s->type, s->lvalue);
	return s;
}

yf_symbol* yf_setsymbol(int i, yf_symboltype type, string value)
{
	if(i>=symbol_table.size())
		return NULL;
	yf_symbol* s = &symbol_table[i];
	s->type = type;
	s->lvalue = yf_addstring(value);
	//printf("SYMBOL(#%d, n:'%s', t:%d, v:'%s')\n", i, s->name.c_str(), s->type, string_table[s->lvalue].c_str());
	return s;
}

int yf_addstring( string s )
{
	int i = string_table.size();
	string_table.insert(string_table.end(), s);
	return i;
}

/* code generation routines */
void out_fmt_hex()
{
	unsigned long imask = (1 << sys.imem_width) -1;
	
	/* output the instruction memory buffer as hex ints */
	for(int i = 0; i<codesize; i++)
		printf("%08x\n", lpimem[i] & imask );
}

void out_fmt_hex_waddr(int ipl)
{
	unsigned long imask = (1 << sys.imem_width) -1;
	
	/* output the instruction memory buffer as hex ints */
	for(int i = 0; i<codesize; i++) {
		if( (i % ipl) == 0 ) {
			if(i>0) printf("\n");
			printf("0x%04x: ", i);
		}
		printf("%04x ", lpimem[i] & imask );
	}
	printf("\n");
}

int gen( unsigned long opcode, unsigned long operand)
{
	int i;
	//printf("%d %d %d %d:   ", opcode, a1, a2, a3);
	opcode <<= (sys.reg_addr_bits*3);
	i = opcode | operand;
	
	if(sys.base < sys.imem ) {
		// check to see if we already have an instruction here
		if(lpimem[ sys.base ] != 0xffffffff) {
			char yerr[1024];
			sprintf(yerr, "line %d : instruction at memory address 0x%08x not empty.\n", yylineno, sys.base );
			printf( yerr );
			exit(0);
		}
		lpimem[ sys.base ] = i;
		sys.base++; // increment the base address
		if(codesize < sys.base)
			codesize = sys.base;
	} else {
		yyerror("out of instruction memory");
		exit(1);
	}
	return 0;
}

