# YourFirstCPU test asm program

	# tell the assembler details about our cpu system configuration
	.imem	 256 16	# instruction memory size is 256 words with 16 bits/instruction
	.regfile 16 4	# regfile has 16 registers with 4 bit addresses

	.define author  "(c)2007 Colin MacKenzie"
	.define url     "http://www.colinmackenzie.net" 
	
	.register r0 x
	.register r1 y
	.register r2 lc		# our loop counter
	.register r4 dec	# our loop decrement value
    .register r5 ret
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
	BRANZ	dec, lc

	LRI	x, 4
	SUB	y, x, y
	HALT

	.end

