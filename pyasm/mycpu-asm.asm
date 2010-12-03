# YourFirstCPU test asm program


define("author","(c)2007 Colin MacKenzie")
define("url","http://www.colinmackenzie.net") 

register('r1','x')
register('r2','y')
register('r3','lc')
register('r4','dec')

base(0x0c)
label('test_sub')
LRI	(3, r4)
SUB (r2, r4, r2)
BRA	(r15)

base(0x00)
label('reset')
LRI	(11,y)
LRI	(3,x)
LRI	(1,r4)
LRI	(10,r3)

label('loop')
ADD	(r2, r1, r2)
SUB	(r3, r4, r3)
NOP()
BRALNZ (loop, r3)

LRI	(4,r1)
SUB	(r2, r1, r2)
CALL (test_sub, r15)
HALT ()


