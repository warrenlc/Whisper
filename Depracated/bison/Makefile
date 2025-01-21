CC=gcc
LEX=flex
YACC=bison
CFLAGS=-Wall
LDLIBS= -lm

all: whisper

whisper: whisper.tab.o whisper.lex.o whisper.o
	$(CC) $(CFLAGS) -o $@ $^ $(LDLIBS)

whisper.tab.o: whisper.tab.c whisper.h
	$(CC) $(CFLAGS) -c $<

whisper.lex.o: whisper.lex.c whisper.h
	$(CC) $(CFLAGS) -c $<

whisper.o: whisper.c whisper.h
	$(CC) $(CFLAGS) -c $<

whisper.tab.c whisper.tab.h: whisper.y
	$(YACC) -d $<

whisper.lex.c: whisper.l
	$(LEX) -o $@ $<

.PHONY: clean

clean:
	rm -f whisper whisper.tab.* whisper.lex.* whisper.o

