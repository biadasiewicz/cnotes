BIN=cnotes
CC=gcc
LIBS=sqlite3
CFLAGS=-std=c89 -pedantic -Wall -Wextra -O0 -g -pipe

$(BIN): main.c
	$(CC) $(CFLAGS) `pkg-config --cflags --libs $(LIBS)` main.c -o $(BIN)

test: $(BIN)
	./tests.sh

clean:
	rm $(BIN)
