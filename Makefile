# HYPERQUEST INFORMATION RETRIEVAL SYSTEM Project Makefile


# this projects source files
PROGRAM = yfasm
SOURCES = main.c parser.c scanner.c 
OBJECTS = main.o parser.o scanner.o 

# install location for libraries
# none

# some useful others that you may need to edit
LEX = flex
YACC = bison
CC = g++

CFLAGS = -g -D_REENTRANT 
LDFLAGS = 
LIBS = 

# name of this file
MF = Makefile


.SUFFIXES: .o .h .cc .l .y

# ------------- Stuff you shouldn't have to change ------------------

main:	$(PROGRAM)
	@ls -l $(PROGRAM)

test: $(PROGRAM)
	@ls -l $(PROGRAM)
	@./$(PROGRAM) test.asm

version:
	$(CC) --version

.cc.o:
	@echo compiling $<
	@$(CC) $(CFLAGS) -c -o $*.o $<

.c.o:
	@echo compiling $<
	@$(CC) $(CFLAGS) -c -o $*.o $<

.l.c:
	@echo building scanner $<
	@$(LEX) -o$*.c $<

.y.c:
	@echo building parser $<
	@$(YACC) --defines=$*.h --output-file=$*.c $<


$(PROGRAM): $(OBJECTS)
	@echo linking...
	@$(CC) -o $(PROGRAM) $(CFLAGS) $(LDFLAGS) $(OBJECTS) $(LIBS)

clean:
	@echo "Deleting temporary files..."
	@rm -f *~ "#*" $(OBJECTS) Makefile.last parser.c parser.h scanner.c yfasm 

rebuild:
	@echo "Deleting intermediate files..."
	@rm -f *~ *.o 
	@make

dep depend:
	@echo 'Updating the dependencies for:'
	@echo '    ' $(SOURCES)
	@{ \
        < $(MF) sed -n '1,/^###.*SUDDEN DEATH/p'; \
            echo '#' ; \
            echo '# dependencies generated on: ' `date` ; \
            echo '#' ; \
            for i in $(SOURCES); do \
                $(CC) -MM $(CFLAGS) $(DEFINES) $$i; \
                echo; \
            done; \
	} > $(MF).new
	@mv $(MF) $(MF).last
	@mv $(MF).new $(MF)

parser.c : parser.y

scanner.c : scanner.l

parser.h : scanner.l

scanner.o : scanner.c

parser.o : parser.c

parser.c : scanner.c

sim:
	iverilog -o test.vvp testbench.v yfcpu.v	
	vvp test.vvp
##################### EVERYTHING BELOW THIS LINE IS SUBJECT TO SUDDEN DEATH...
#
# dependencies generated on:  Mon Oct 18 22:07:55 CEST 2010
#
main.o: main.c yfasm.h

parser.o: parser.c yfasm.h yfsys.h

scanner.o: scanner.c parser.h yfasm.h

