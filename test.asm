# YourFirstCPU test asm program

	# tell the assembler details about our cpu system configuration
	.imem	 256 28	# instruction memory size is 256 words with 16 bits/instruction
	.regfile 16  8	# regfile has 16 registers with 4 bit addresses

	.define author  "(c)2007 Colin MacKenzie"
	.define url     "http://www.colinmackenzie.net" 
	
	.register r1 x
	.register r2 y
	.register r3 lc		# our loop counter
	.register r4 dec	# our loop decrement value

	.base	0x0c	# place this subroutine at mem addr 0x0c
test_sub:
	LRI	dec, 3
	SUB	y, dec, y
	BRA	r15

	# reset vector
	.base	0x00
reset:
	LRI	y, 11
	LRI	x, 3
	LRI	dec, 1
	LRI	lc, 10

loop:
	ADD	y, x, y
	SUB	lc, dec, lc
	NOP
	BRALNZ	loop, lc

	LRI	x, 4
	SUB	y, x, y
	CALL	test_sub, r15
	HALT

	.end

