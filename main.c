/* Additional C code */
/* Error processor for yyparse */

#include <stdio.h>

#include "yfasm.h"

int output_symbols = 1;


int yyparse();


/*--------------------------------------------------------*/
/* The controlling function */
int main(int argc, const char* argv[])
{
    extern FILE *yyin;

    // allocate the instruction memory for our output
    if(!lpimem)
	    alloc_imem( sys.imem ); 

    /* TODO: Process command line arguments. for now, we process all files on command line and output to STDOUT 
     */
    if(argc>1) {
	    /* process all files on the command line */
	    for(int i=1; i<argc; i++) {
    		yyin = fopen( argv[i], "r" );
		yyparse();
		fclose( yyin );
	    }
    } else {
	    /* interactive mode */
	    yyparse();
    }

    /* output our instruction memory buffer */
    out_fmt_hex();

    if(output_symbols) {
	    /* output the list of symbols */
	    printf("\nSymbol Table:\n");
	    for(yf_symbols::const_iterator s=symbol_table.begin(), _s=symbol_table.end(); s!=_s; s++) {
		switch(s->type) {
			case ST_UNKNOWN  : printf("  %15s  UNKOWN\n", s->name.c_str() ); break;
			case ST_LABEL    : printf("  %15s  LABEL      0x%08x\n", s->name.c_str(), s->lvalue ); break;
			case ST_STRING   : printf("  %15s  STRING     \"%s\"\n", s->name.c_str(), string_table[s->lvalue].c_str()); break;
			case ST_INT      : printf("  %15s  INT        %d\n", s->name.c_str(), s->lvalue ); break;
			case ST_REGISTER : printf("  %15s  REGISTER   r%d\n", s->name.c_str(), s->lvalue ); break;
			default:
				         printf("  %15s  ERROR\n", s->name.c_str() );
		}
    	}
    }

    /* free instruction memory buffer */
   // if(lpimem)
	//free( lpimem );
    
    return 0;
}

