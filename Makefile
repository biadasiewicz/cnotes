BIN=cnotes
CC=gcc
LIBS=sqlite3
CFLAGS=-std=c89 -pedantic -Wall -Wextra -O0 -g -pipe

all:
	$(CC) $(CFLAGS) `pkg-config --cflags --libs $(LIBS)` main.c -o $(BIN)

test:
	@./tests.sh

clean:
	rm $(BIN)
