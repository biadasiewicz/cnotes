#!/bin/bash

rm -f test.sqlite3 || true

export CNOTES=key

function test_output_after_write {
    OUTPUT=$(./cnotes read)
    COUNT=$(echo "$OUTPUT" | wc -l)
    if [ $COUNT != "$2" ]; then
        echo "$LINENO: incorrect number of notes '$COUNT' expected '$2'"
        echo "$OUTPUT"
        exit
    fi

    COUNT=$(echo "$OUTPUT" | grep ".*|$1|.*" | wc -l)
    if [ $COUNT != "$3" ]; then
        echo "$LINENO: expected '$1' to be printed '$3' times in format '.*|$1|.*' but printed '$COUNT' times"
        echo "$OUTPUT"
        exit
    fi
}

./cnotes write "first"
test_output_after_write "first" 1 1
./cnotes write "second"
test_output_after_write "second" 2 1
./cnotes write "second"
test_output_after_write "second" 3 2


function test_read_specific_note {
    ID=$1
    EXPECTED=$2
    OUTPUT=$(./cnotes read $ID)
    COUNT=$(echo "$OUTPUT" | grep "$ID|.*|.*" | wc -l)
    if [ $COUNT != $EXPECTED ]; then
        echo "$LINENO: expected id '$ID' printed '$EXPECTED' number of times, but printed '$COUNT'"
        echo "$OUTPUT"
        exit
    fi
}

function test_read_note_id_0 {
    OUTPUT=$(./cnotes read 0)
    if [ "$OUTPUT" != "note id=0 does not exist" ]; then
        echo "$LINENO: wrong output"
        echo "$OUTPUT"
        exit
    fi
}

test_read_specific_note 1 1
test_read_specific_note 2 1
test_read_specific_note 3 1
test_read_specific_note 4 0
test_read_note_id_0


#test tags inserted to database

function test_tag_in_db {
    OUTPUT=$(sqlite3 test.sqlite3 "SELECT * FROM Tags;")
    COUNT=$(echo "$OUTPUT" | grep "$1" | wc -l)
    if [ $COUNT != "1" ]; then
        echo "$LINENO: '$1' found '$COUNT' number of times: $OUTPUT"
        exit
    fi
}
./cnotes write "tagged note #a"
./cnotes write "tagged note #b"
test_tag_in_db "a"
test_tag_in_db "b"

#test tags are unique
./cnotes write "tagged note #a"
test_tag_in_db "a"



#test reading tags

function test_read_tag {
    OUTPUT=$(./cnotes tag "$1")
    COUNT=$(echo "$OUTPUT" | grep "#$1" | wc -l)
    if [ $COUNT != "$2" ]; then
        echo "$LINENO: '$1' found '$COUNT' number of times but expected '$2'"
        echo "$OUTPUT"
        exit
    fi
}

test_read_tag "a" 2
test_read_tag "b" 1
test_read_tag "thistagdontexists" 0


#test reading all tags

function test_tags {
    OUTPUT=$(./cnotes tag)
    if [ "$OUTPUT" != "$1" ]; then
        echo "$LINENO: '$1' not found in: '$OUTPUT'"
        exit
    fi
}

test_tags $'1|a\n2|b'


#test removing note
./cnotes write "#delete"
COUNT_BEFORE=$(./cnotes tag "delete" | grep "delete" | wc -l)
./cnotes delete 7
COUNT=$(./cnotes tag "delete" | grep "delete" | wc -l)
if [ $COUNT == $COUNT_BEFORE ]; then
    echo "$LINENO: 'delete' tag not deleted: '$COUNT' but expected '$COUNT_BEFORE'"
    exit
fi

if [ $(./cnotes tag | grep "delete" | wc -l) == "1" ]; then
    echo "$LINENO: 'delete' tag not deleted from Tags table"
fi
