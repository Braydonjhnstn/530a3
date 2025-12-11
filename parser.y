/*
##
## parser.y
## Name: Braydon Johnston REDid: 131049942 Class Acc: cssc2115
## Assignment 3
## CS530-03 Fall 2025
##
*/

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// external functions from lexer
extern int yylineno;                   // current line number
extern FILE *yyin;                     // input file
extern int yylex(void);                // lexer function
int yyparse(void);                     // parser function
void yyerror(const char *s);           // error handler

// global state variables
int parse_error = 0;                   // flag for parse errors
char error_message[256] = "";          // error message to display
int invalid_token_seen = 0;            // flag for invalid token
char invalid_token_text[256] = "";     // text of invalid token
int last_token = 0;                    // last token type (for error reporting)
int op_op_error = 0;                   // flag for consecutive operator error

%}

// token definitions
%token ID OP_PLUS OP_MINUS OP_MULT OP_DIV OP_MOD
%token ASSIGN SEMICOLON LPAREN RPAREN NEWLINE INVALID

// operator precedence rules
%nonassoc LPAREN RPAREN    // parentheses are non-associative
%left OP_PLUS OP_MINUS     // + and - are left-associative, lower precedence
%left OP_MULT OP_DIV OP_MOD // *, /, % are left-associative, higher precedence

%%

// grammar rules start here
program:
    /* empty */                        // program can be empty
    | program statement NEWLINE        // program with statement and newline
    | program statement                // program with statement (no newline at end)
    ;

// a statement is either an assignment or an expression
statement:
    assignment
    | expression
    ;

// assignment: id = expression ;
assignment:
    ID ASSIGN expression SEMICOLON
    ;

// atom is either an id or a parenthesized id op id
// these can appear anywhere an id would appear
atom:
    ID
    | LPAREN ID OP_PLUS ID RPAREN
    | LPAREN ID OP_MINUS ID RPAREN
    | LPAREN ID OP_MULT ID RPAREN
    | LPAREN ID OP_DIV ID RPAREN
    | LPAREN ID OP_MOD ID RPAREN
    ;

// expression: id op id {op id} with optional parentheses
// strictly right-associative, always extends to the right
expression:
    atom OP_PLUS atom                  // base case: two atoms with operator
    | atom OP_MINUS atom
    | atom OP_MULT atom
    | atom OP_DIV atom
    | atom OP_MOD atom
    | expression OP_PLUS atom          // recursive: extend expression to the right
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

