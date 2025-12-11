%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylineno;
extern FILE *yyin;
extern int yylex(void);
int yyparse(void);
void yyerror(const char *s);

int parse_error = 0;
char error_message[256] = "";
int invalid_token_seen = 0;
char invalid_token_text[256] = "";
int last_token = 0;
int op_op_error = 0;

%}

%token ID OP_PLUS OP_MINUS OP_MULT OP_DIV OP_MOD
%token ASSIGN SEMICOLON LPAREN RPAREN NEWLINE INVALID

%nonassoc LPAREN RPAREN
%left OP_PLUS OP_MINUS
%left OP_MULT OP_DIV OP_MOD

%%

program:
    /* empty */
    | program statement NEWLINE
    | program statement
    ;

statement:
    assignment
    | expression
    ;

assignment:
    ID ASSIGN expression SEMICOLON
    ;

/* Atom: id or (id op id) - can appear where an id would appear */
atom:
    ID
    | LPAREN ID OP_PLUS ID RPAREN
    | LPAREN ID OP_MINUS ID RPAREN
    | LPAREN ID OP_MULT ID RPAREN
    | LPAREN ID OP_DIV ID RPAREN
    | LPAREN ID OP_MOD ID RPAREN
    ;

/* Expression: id op id {op id} with optional parentheses */
/* Strictly right-associative: always extend to the right */
expression:
    atom OP_PLUS atom
    | atom OP_MINUS atom
    | atom OP_MULT atom
    | atom OP_DIV atom
    | atom OP_MOD atom
    | expression OP_PLUS atom
    | expression OP_MINUS atom
    | expression OP_MULT atom
    | expression OP_DIV atom
    | expression OP_MOD atom
    ;

%%

void yyerror(const char *s) {
    parse_error = 1;
    extern int yychar;
    
    // Check for op op error first (takes precedence over invalid token)
    if (op_op_error) {
        snprintf(error_message, sizeof(error_message), "op op");
        op_op_error = 0;
        // Clear invalid token since op op takes precedence
        invalid_token_seen = 0;
        invalid_token_text[0] = '\0';
    } else if (yychar == INVALID || invalid_token_seen) {
        // Report the invalid token
        // If invalid_token_seen is set, that's the token that should be reported (like ":")
        // Otherwise, report the stored token (like "24")
        if (strlen(invalid_token_text) > 0) {
            snprintf(error_message, sizeof(error_message), "invalid token \"%s\"", invalid_token_text);
        } else {
            snprintf(error_message, sizeof(error_message), "invalid token");
        }
        invalid_token_text[0] = '\0';
        invalid_token_seen = 0;
    } else if (yychar == ASSIGN || (yychar == NEWLINE && last_token != SEMICOLON && last_token != 0) || yychar == 0) {
        snprintf(error_message, sizeof(error_message), "invalid assignment");
    } else if (yychar == SEMICOLON) {
        snprintf(error_message, sizeof(error_message), "missing expression");
    } else {
        snprintf(error_message, sizeof(error_message), "syntax error");
    }
}

