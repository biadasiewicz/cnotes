#!/bin/bash

rm -f db.sqlite3 || true

function test_output_after_write {
    COUNT=$(sqlite3 db.sqlite3 "select * from Notes;"| wc -l)
    if [ $COUNT != "$2" ]; then
        echo "$LINENO: '$1' printed an incorrect number of times, expected: $2"
        exit
    fi
    if [ $(sqlite3 db.sqlite3 "select * from Notes;"| grep ".*|$1|.*" | wc -l) != "$3" ]; then
        echo "$LINENO: expected '$1' printed '$3' times"
        exit
    fi
}

./cnotes write "first"
test_output_after_write "first" 1 1
./cnotes write "second"
test_output_after_write "second" 2 1
./cnotes write "second"
test_output_after_write "second" 3 2
