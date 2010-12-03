import re
import sys
from array import array

INST_SHIFT  = 24
SLOT1_SHIFT = 16 
SLOT2_SHIFT = 8
SLOT3_SHIFT = 0

DEF_IMEM            = 256
DEF_IMEM_WIDTH	    = 32
DEF_REGISTERS	    = 16
DEF_OPCODE_WIDTH    = 4
DEF_REG_ADDR_WIDTH  = 8
DEF_BASE		    = 0

OP_NOP      = 0x0
OP_LRI	    = 0x1
OP_ADD	    = 0x4
OP_SUB	    = 0x5
OP_OR       = 0x6
OP_XOR	    = 0x7
OP_BRA	    = 0x8
OP_BRANZ	= 0x9
OP_BRAL	    = 0xa
OP_BRALNZ	= 0xb
OP_CALL	    = 0xc
OP_HALT	    = 0xf

'''

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

0x00 01000b02 0001 00000000 00001011 00000010 LRI    0x00 0x0b 0x02
0x01 01000301 0001 00000000 00000011 00000001 LRI    0x00 0x03 0x01
0x02 01000104 0001 00000000 00000001 00000100 LRI    0x00 0x01 0x04
0x03 01000a03 0001 00000000 00001010 00000011 LRI    0x00 0x0a 0x03
0x04 04020102 0100 00000010 00000001 00000010 ADD    0x02 0x01 0x02
0x05 05030403 0101 00000011 00000100 00000011 SUB    0x03 0x04 0x03
0x06 00000000 0000 00000000 00000000 00000000 NOP    0x00 0x00 0x00
0x07 0b030400 1011 00000011 00000100 00000000 BRALNZ 0x03 0x04 0x00
0x08 01000401 0001 00000000 00000100 00000001 LRI    0x00 0x04 0x01
0x09 05020102 0101 00000010 00000001 00000010 SUB    0x02 0x01 0x02
0x0a 0c000c0f 1100 00000000 00001100 00001111 CALL   0x00 0x0c 0x0f
0x0b 0f000fff 1111 00000000 00001111 11111111 HALT   0x00 0x0f 0xff
0x0c 01000304 0001 00000000 00000011 00000100 LRI    0x00 0x03 0x04
0x0d 05020402 0101 00000010 00000100 00000010 SUB    0x02 0x04 0x02
0x0e 08000f00 1000 00000000 00001111 00000000 BRA    0x00 0x0f 0x00
'''

class Enviroment(dict):
    
    def __setitem__(self,key,value):
        if key in ALIAS:
            print "Found Alias %s" % key
            key = ALIAS[key]
        e = re.compile("^r([\d]{1,2})$").search(key)
        if e:
            value = int(e.groups()[0])           
        super(Enviroment, self).__setitem__(key, value)    

    def __getitem__(self,key):
        e = re.compile("^r([\d]{1,2})$").search(key)
        if e:
            ret = int(e.groups()[0])           
        else:
            ret = super(Enviroment, self).__getitem__(key)    
        print "get ",key,ret
        return ret

    def get(self,key):
        print "get "
        return super(Enviroment, self).get(key)    

class Progmem():
    
    def __init__(self):
        self.mem = {}
        self.address = 0
        self.iteridx = 0
    def add(self,code):
        if self.address in self.mem:
            raise Exception("Overlapping code at 0x%i" % self.address)
        self.mem[self.address] = code
        self.address += 1
    def rebase(self,address):
        self.address = int(address) 
    def pc(self):
        return self.address
    def __iter__(self):
        self.iteridx = 0
        return self
    def next(self):
        if self.iteridx not in self.mem:
            raise StopIteration
        ret = self.mem[self.iteridx]
        self.iteridx+=1
        return ret
    
PROGRAM = Progmem()
ENV = Enviroment()
MEM = list([0 for x in range(0,DEF_REGISTERS)])
ALIAS = {}

class ASM: 
    '''Base ASM instruction''' 
    def __init__(self):
        PROGRAM.add(self)
    def genbits(self): 
        '''Generate bits, 'code' and '_genbits' will be defined in each derived class '''
        return (self.code << INST_SHIFT) | self._genbits()
    
class OP0(ASM): 
    def __init__(self):
        ASM.__init__(self) 
    def _genbits(self): 
        print self.name
        return 0L
        
class OP1(ASM): 
    def __init__(self, dest):
        ASM.__init__(self) 
        self.dest = dest
    def _genbits(self): 
        print self.name,self.dest
        return (self.dest << SLOT3_SHIFT)

class NOP(OP0): 
    code = OP_NOP
    name = "nop"
    
class LRI(ASM): 
    "LRI format_rd_imm   { gen( xLRI, $2)"
    code = OP_LRI
    name = "lri"
    def __init__(self, a, b):
        ASM.__init__(self) 
        self.a = a
        self.b = b
    def _genbits(self): 
        print "%-8s 0x%02x 0x%02x" % (self.name,self.a,self.b)
        return (self.a << SLOT2_SHIFT)  | \
                (self.b << SLOT3_SHIFT)

class ADD(ASM): 
    '''ADD format_ra_rb_rd { gen( xADD, $2 )'''
    code = OP_ADD
    name = "add"
    def __init__(self, a,b,c):
        ASM.__init__(self) 
        self.a = a
        self.b = b 
        self.c = c
    def _genbits(self): 
        print "%-8s 0x%02x 0x%02x 0x%02x" % (self.name,self.a,self.b,self.c)
        return (self.a << SLOT1_SHIFT)  | \
                (self.b << SLOT2_SHIFT) | \
                (self.c << SLOT3_SHIFT)

class SUB(ADD): 
    code = OP_SUB
    name = "sub"

class OR(ADD): 
    code = OP_OR
    name = "or"

class XOR(ADD): 
    code = OP_XOR
    name = "xor"

class BRA(ADD): 
    code = OP_BRA
    name = "bra"
    def __init__(self, a):
        ASM.__init__(self) 
        self.a = a
    def _genbits(self): 
        print "%-8s 0x%02x" % (self.name,self.a)
        return (self.a << SLOT2_SHIFT)

class BRANZ(ASM): 
    code = OP_BRANZ
    name = "branz"
    def __init__(self, a, b):
        ASM.__init__(self) 
        self.a = a
        self.b = b
    def _genbits(self): 
        print "%-8s 0x%02x 0x%02x" % (self.name,self.a,self.b)
        return (self.a << SLOT1_SHIFT)  | \
                (self.b << SLOT2_SHIFT)

class BRAL(OP1): 
    code = OP_BRAL
    name = "bral"

class BRALNZ(BRANZ): 
    code = OP_BRALNZ
    name = "bralnz"
    def __init__(self, a, b):
        ASM.__init__(self) 
        self.a = a
        self.b = b
    def _genbits(self): 
        print "%-8s 0x%02x 0x%02x" % (self.name,self.a,self.b)
        return (self.b << SLOT1_SHIFT)  | \
                (self.a << SLOT2_SHIFT)

class CALL(ASM): 
    code = OP_CALL
    name = "call"
    def __init__(self, a, b):
        ASM.__init__(self) 
        self.a = a
        self.b = b
    def _genbits(self): 
        print "%-8s 0x%02x 0x%02x" % (self.name,self.a,self.b)
        return (self.a << SLOT2_SHIFT)  | \
                (self.b << SLOT3_SHIFT)

class HALT(OP0): 
    code = OP_HALT
    name = "halt"
    
def label(name): 
    '''Setting a label''' 
    ENV[name] = PROGRAM.pc()

def define(name,value): 
    if name in ENV:
        raise Exception("Conflicting value in global scope for %s" % name)
    ENV['name'] = value

def register(reg,alias):
    if alias in ALIAS:
        raise Exception("Conflicting value in register scope for %s" % name)
    print "Alias %s -> %s" % (alias,reg) 
    e = re.compile("^r([\d]{1,2})$").search(reg)
    value = int(e.groups()[0])           
    ENV[alias] = value    
    ALIAS[alias] = reg

def base(address): 
    PROGRAM.rebase(address)

def main():
    infile = sys.argv[1]
    outfile = infile.replace(".asm","")
    for i in range(DEF_REGISTERS):
        ENV["r%d" % i] = 0
    for op in (NOP,ADD, SUB, LRI, ADD, SUB, OR, XOR, BRA, BRANZ, 
                BRAL, BRALNZ, CALL, HALT, label,define, register,base): 
        ENV[op.__name__] = op
        
    execfile(infile, ENV, {})
    a = array("I") # Unsigned short array 
    f = open(outfile, "w")
    for cmd in PROGRAM:
        f.write("%08x\n" % cmd.genbits()) 
    f.close()
if __name__ == "__main__":
    main()        