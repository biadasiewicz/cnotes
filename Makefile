BIN=cnotes
CC=gcc
LIBS=sqlite3
CFLAGS=-std=c89 -pedantic -Wall -Wextra -O0 -g -pipe

$(BIN): main.c
	$(CC) $(CFLAGS) `pkg-config --cflags --libs $(LIBS)` main.c -o $(BIN)

release:
	$(CC) -DNDEBUG main.c -lsqlite3 -std=c89 -pedantic -Wall -Wextra -O2 -o cnotes

test: $(BIN)
	./tests.sh

clean:
	rm $(BIN)

printdb:
	sqlite3 db.sqlite3 "select * from Notes;"
	sqlite3 db.sqlite3 "select * from Tags;"
	sqlite3 db.sqlite3 "select * from TagNoteMap;"
