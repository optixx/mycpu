import os
import sys 
import re


def op(v):
    m = {
        '0000' : 'NOP',
        '0001' : 'LRI',
        '0100' : 'ADD',
        '0101' : 'SUB',
        '0110' : 'OR',
        '0111' : 'XOR',
        '1000' : 'BRA',     # branch to address in memory location RB
        '1001' : 'BRANZ',   # branch to address in memory location RB, if RA is zero
        '1010' : 'BRAL',    # branch to literal address RB
        '1011' : 'BRALNZ',   # branch to literal address RB, if RA is zero
        '1100' : 'CALL',   
        '1111' : 'HALT',
    }
    return m[v]

def b(v,bits=16):
    o = str()
    for i in range(bits-1,-1,-1):
        s = 1<<i
        if  v & s:
            o += "1"
        else:
            o += "0"
        if i and not i%8:
            o += " "
    return o



def main(filename):
    data = open(filename,"r").read().split("\n")
    for idx,line in enumerate(data):
        if re.compile("[a-zA-Z0-9]{4}").search(line):
            val = int(line,16)
            bin =  b(val)
            RA = (val >> 8)  & 0x0F 
            RB = (val >> 4) & 0x0F
            RD = (val) & 0x0F
            print "0x%02x %s %s %-6s 0x%02x 0x%02x 0x%02x" % (idx, line, bin,op(bin[:4]),RA,RB,RD)



if __name__ == '__main__':
    main(sys.argv[1])
