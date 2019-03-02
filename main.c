#include <sqlite3.h>
#include <regex.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#define ERROR_INFO_FORMAT "[%s:%d] "
#define ERROR_INFO_ARGS __FILE__, __LINE__
#define print_error_msg(msg) fprintf(stderr, ERROR_INFO_FORMAT "%s\n",\
        ERROR_INFO_ARGS, msg)
#define print_sqlite_error() fprintf(stderr, ERROR_INFO_FORMAT "%s\n",\
        ERROR_INFO_ARGS, sqlite3_errmsg(db))
#define die() exit(EXIT_FAILURE);
#define die_msg(msg) do { print_error_msg(msg); die(); } while(0)
#define die_sqlite() do { print_sqlite_error(); die(); } while(0)

static sqlite3 *db;
#define DB_FILEPATH "db.sqlite3"

static void open_database()
{
    char const* sql;
    char *err_msg;

    if(sqlite3_open(DB_FILEPATH, &db) != SQLITE_OK)
        die_sqlite();

    sql = "CREATE TABLE IF NOT EXISTS Notes("
          "ID INTEGER PRIMARY KEY AUTOINCREMENT, content TEXT, time TIMESTAMP);"
          "CREATE TABLE IF NOT EXISTS Tags("
          "ID INTEGER PRIMARY KEY AUTOINCREMENT, tagname TEXT UNIQUE NOT NULL);";

    if(sqlite3_exec(db, sql, NULL, NULL, &err_msg) != SQLITE_OK)
    {
        print_error_msg(err_msg);
        sqlite3_free(err_msg);
        die();
    }
}

static void exit_cnotes()
{
    sqlite3_close(db);
}

static void
insert_tag(char const* note, int note_id, regoff_t begin, regoff_t end)
{
    sqlite3_stmt *res;
    char const* sql;
    int rc;

    sql = "INSERT INTO Tags(tagname) VALUES(?);";

    if(sqlite3_prepare_v2(db, sql, -1, &res, NULL) != SQLITE_OK)
    {
        die_sqlite();
    }

    if(sqlite3_bind_text(res, 1, note + begin, end - begin, NULL) != SQLITE_OK)
    {
        sqlite3_finalize(res);
        die_sqlite();
    }

    rc = sqlite3_step(res);
    sqlite3_finalize(res);

    if(rc == SQLITE_DONE || rc == SQLITE_CONSTRAINT ||
       rc == SQLITE_CONSTRAINT_UNIQUE)
    {
        return;
    }
    else
    {
        die_sqlite();
    }
}

static void insert_tags(char const* note, int note_id)
{
    char *err_msg; size_t count;
    int rc;
    regex_t regex;
    regmatch_t matches[2];

    rc = regcomp(&regex, "#\\([[:alnum:]]\\+\\)", 0);
    if(rc)
    {
        count = regerror(rc, &regex, NULL, 0);
        err_msg = malloc(count);
        regerror(rc, &regex, err_msg, count);
        print_error_msg(err_msg);
        free(err_msg);
        die();
    }

    while((rc = regexec(&regex, note, 2, matches, 0)) == 0)
    {
        insert_tag(note, note_id, matches[1].rm_so, matches[1].rm_eo);
        note += matches[1].rm_eo;
    }
    regfree(&regex);

    if(rc == REG_ESPACE)
    {
        die_msg(strerror(errno));
    }
}

static void write_note(char const* note)
{
    sqlite3_stmt *res;
    char const* sql;

    open_database();

    sql = "INSERT INTO Notes(content, time) VALUES(?, CURRENT_TIMESTAMP);";

    if(sqlite3_prepare(db, sql, -1, &res, NULL) != SQLITE_OK)
    {
        die_sqlite();
    }

    if(sqlite3_bind_text(res, 1, note, -1, NULL) != SQLITE_OK)
    {
        sqlite3_finalize(res);
        die_sqlite();
    }

    if(sqlite3_step(res) != SQLITE_DONE)
    {
        sqlite3_finalize(res);
        die_sqlite();
    }

    sqlite3_finalize(res);

    insert_tags(note, sqlite3_last_insert_rowid(db));
}

static int print_note(void *arg, int argc, char **values, char **columns)
{
    (void) arg; (void) argc; (void) columns;

    printf("%s|%s|%s\n", values[0], values[1], values[2]);

    return 0;
}

static void read_note()
{
    char const* sql;
    char *err_msg;

    sql = "SELECT * FROM Notes;";

    open_database();

    if(sqlite3_exec(db, sql, print_note, NULL, &err_msg) != SQLITE_OK)
    {
        print_error_msg(err_msg);
        sqlite3_free(err_msg);
        die();
    }
}

int main(int argc, char **argv)
{
    atexit(exit_cnotes);

    if(argc < 2 || (argc >= 2 && strcmp(argv[1], "help") == 0))
    {
        printf("help message\n");
    }
    else if(strcmp(argv[1], "write") == 0)
    {
        if(argc < 3)
        {
            die_msg("too few arguments");
        }

        write_note(argv[2]);
    }
    else if(strcmp(argv[1], "read") == 0)
    {
        read_note();
    }
    else
    {
        die_msg("unknown command");
    }
    return EXIT_SUCCESS;
}
