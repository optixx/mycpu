#include <vector>
#include <string>

using namespace std;

/* yacc forward declerations */
int yyerror(const char* err);
int yylex();
extern int yylineno;
extern char* yytext;

/* this struct holds our cpu system description */
typedef struct {
	unsigned long imem;
	unsigned long imem_width;
	unsigned long regfile;
	unsigned long opcode_bits;
	unsigned long reg_addr_bits;
	unsigned long base;
} yf_sysinfo;

/* symbol type enumerations */
typedef enum {
	ST_UNKNOWN = 0,
	ST_LABEL,
	ST_STRING,
	ST_INT,
	ST_REGISTER
} yf_symboltype;

/* symbol table entry */
typedef struct {
	string name;
	yf_symboltype type;
	long lvalue;
} yf_symbol;

/* decleration of symbol table and string table */
typedef vector< yf_symbol > yf_symbols;
typedef vector< string > yf_strings;

/* declaration of global variables */
extern yf_sysinfo sys;
extern yf_symbols symbol_table;
extern yf_strings string_table;

/* our assembler instruction memory */
extern unsigned long* lpimem;
void alloc_imem( unsigned long newsize );

/* holds the highest code address */
extern unsigned long codesize; 


/* symbol table functions */
int yf_getsymbol(string name);
yf_symbol yf_getsymbol(int i);
int yf_addsymbol(string name, yf_symboltype type, long lvalue);
int yf_addsymbol(string name, yf_symboltype type, string lvalue);
yf_symbol* yf_setsymbol(int i, yf_symboltype type, long value);
yf_symbol* yf_setsymbol(int i, yf_symboltype type, string value);

/* string table functions */
int yf_addstring( string s );

/* outputs the assembled instruction memory in various formats */
void out_fmt_hex();
void out_fmt_hex_waddr(int ipl); // ipl = instructions per line

// macro encodes ra, rb, rd into a single operand value
#define ENCR(ra, rb, rd) ( ((ra) << (sys.reg_addr_bits*2)) | ((rb) << sys.reg_addr_bits) | (rd) )

/* generates assembler instruction given opcode and operand */
int gen( unsigned long opcode, unsigned long operand );


