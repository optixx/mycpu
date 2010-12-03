import re
import sys
from array import array
INST_SHIFT = 0
SLOT1_SHIFT = 4
SLOT2_SHIFT = 4
SLOT3_SHIFT = 4
PROGRAM = []
ENV = Enviroment()
MEM = []
class Enviroment(dict):
    
    def __setitem__(key,value):
        print "set ",key,value
        e = re.compile("^r([\d]{1,2})$").search(key):
        if e:
            print e
        super(Memory, self).__setitem__(key, value)    

class ASM: 
    '''Base ASM instruction''' 
    def __init__(self):
        #self.file, self.line = here() 
        PROGRAM.append(self)
    def genbits(self): 
        '''Generate bits, 'code' and '_genbits' will be defined in each derived class '''
        return (self.code << INST_SHIFT) | self._genbits()
    
class ALU3(ASM): 
    '''ALU instruction with 3 operands''' 
    def __init__(self, src1, src2, dest):
        ASM.__init__(self) 
        self.src1 = src1 
        self.src2 = src2 
        self.dest = dest
    def _genbits(self): 
        print self.name,self.src1,self.src2,self.dest
        return (self.src1 << SLOT1_SHIFT)  | \
                (self.src2 << SLOT2_SHIFT) | \
                (self.dest << SLOT3_SHIFT)

class OP1(ASM): 
    def __init__(self, dest):
        ASM.__init__(self) 
        self.dest = dest
    def _genbits(self): 
        print self.name,self.dest
        return (self.dest << SLOT3_SHIFT)

class OP2(ASM): 
    def __init__(self, src1, dest):
        ASM.__init__(self) 
        self.src1 = src1 
        self.dest = dest
    def _genbits(self): 
        print self.name,self.src1,self.dest
        return (self.src1 << SLOT1_SHIFT)  | \
                (self.dest << SLOT3_SHIFT)

class add(ALU3): 
    code = 0
    name = "add"
    
class sub(ALU3): 
    code = 1
    name = "sub"

class move(OP2): 
    code = 2
    name = "move"

class store(OP2): 
    code = 3
    name = "store"

class load(OP2): 
    code = 4
    name = "load"

class jmp(OP1): 
    code = 5
    name = "jmp"
    
def label(name): 
    '''Setting a label''' 
    ENV[name] = len(PROGRAM)

    
def main():
    infile = sys.argv[1]
    outfile = infile.replace(".asm","")
    # Add registers 
    for i in range(8):
        ENV["r%d" % i] = 0
    # Add operators 
    for op in (add, sub, move, load, store, label,jmp): 
        ENV[op.__name__] = op
        
    execfile(infile, ENV, {})
    a = array("H") # Unsigned short array 
    for cmd in PROGRAM:
        a.append(cmd.genbits()) 
    open(outfile, "wb").write(a.tostring())
if __name__ == "__main__":
    main()        