/* system defines for YourFirstCPU
 *
 * 
 */

/* default system parameters */
#define DEF_IMEM		    256
#define DEF_IMEM_WIDTH		32
#define DEF_REGFILE		    16
#define DEF_OPCODE_WIDTH	4
#define DEF_REG_ADDR_WIDTH	8
#define DEF_BASE		    0


/* mnemonic opcode values */
#define xNOP	0x0
#define xLRI	0x1
#define xADD	0x4
#define xSUB	0x5
#define xOR	    0x6
#define xXOR	0x7
#define xBRA	0x8
#define xBRANZ	0x9
#define xBRAL	0xa
#define xBRALNZ	0xb
#define xCALL	0xc
#define xHALT	0xf



