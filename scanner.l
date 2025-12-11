/*
##
## scanner.l
## Name: Braydon Johnston REDid: 131049942 Class Acc: cssc2115
## Assignment 3
## CS530-03 Fall 2025
##
*/

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

// external variables we need to update
extern int yylval;                     // token value (not really used here)
extern int invalid_token_seen;          // flag for invalid token
extern char invalid_token_text[256];    // text of the invalid token
extern int last_token;                 // track last token for op op detection
extern int op_op_error;                // flag for consecutive operator error
%}

%option noyywrap
%option yylineno
%option nounput
%option noinput

%%

[ \t\r]+                  { /* ignore whitespace and carriage returns */ }
\n                        { return NEWLINE; }

[0-9]+[a-zA-Z][a-zA-Z0-9]* { /* identifiers that start with a digit are invalid (like "2two" or "24abc") */
                            invalid_token_seen = 1;
                            strncpy(invalid_token_text, yytext, sizeof(invalid_token_text) - 1);
                            invalid_token_text[sizeof(invalid_token_text) - 1] = '\0';
                            return INVALID; 
                          }
[0-9]+                    { /* pure numbers are also invalid (identifiers must start with a letter) */
                            /* store this invalid token, but only if we haven't seen a better one */
                            /* (like ":" which was detected in pre-scan) */
                            if (!invalid_token_seen) {
                                strncpy(invalid_token_text, yytext, sizeof(invalid_token_text) - 1);
                                invalid_token_text[sizeof(invalid_token_text) - 1] = '\0';
                            }
                            return INVALID; 
                          }
[a-zA-Z][a-zA-Z0-9]*      { /* valid identifiers start with a letter, then can have letters or digits */
                            last_token = ID; return ID; 
                          }
"+"                       { 
                            /* if last token was an operator, we have op op error */
                            if (last_token == OP_PLUS || last_token == OP_MINUS || 
                                last_token == OP_MULT || last_token == OP_DIV || 
                                last_token == OP_MOD || last_token == ASSIGN) {
                                op_op_error = 1;
                            }
                            last_token = OP_PLUS;
                            return OP_PLUS; 
                          }
"-"                       { 
                            /* check for op op */
                            if (last_token == OP_PLUS || last_token == OP_MINUS || 
                                last_token == OP_MULT || last_token == OP_DIV || 
                                last_token == OP_MOD || last_token == ASSIGN) {
                                op_op_error = 1;
                            }
                            last_token = OP_MINUS;
                            return OP_MINUS; 
                          }
"*"                       { 
                            /* check for op op */
                            if (last_token == OP_PLUS || last_token == OP_MINUS || 
                                last_token == OP_MULT || last_token == OP_DIV || 
                                last_token == OP_MOD || last_token == ASSIGN) {
                                op_op_error = 1;
                            }
                            last_token = OP_MULT;
                            return OP_MULT; 
                          }
"/"                       { 
                            /* check for op op */
                            if (last_token == OP_PLUS || last_token == OP_MINUS || 
                                last_token == OP_MULT || last_token == OP_DIV || 
                                last_token == OP_MOD || last_token == ASSIGN) {
                                op_op_error = 1;
                            }
                            last_token = OP_DIV;
                            return OP_DIV; 
                          }
"%"                       { 
                            /* check for op op */
                            if (last_token == OP_PLUS || last_token == OP_MINUS || 
                                last_token == OP_MULT || last_token == OP_DIV || 
                                last_token == OP_MOD || last_token == ASSIGN) {
                                op_op_error = 1;
                            }
                            last_token = OP_MOD;
                            return OP_MOD; 
                          }
"="                       { 
                            /* check for op op (like "= =") */
                            if (last_token == OP_PLUS || last_token == OP_MINUS || 
                                last_token == OP_MULT || last_token == OP_DIV || 
                                last_token == OP_MOD || last_token == ASSIGN) {
                                op_op_error = 1;
                            }
                            last_token = ASSIGN;
                            return ASSIGN; 
                          }
";"                       { last_token = SEMICOLON; return SEMICOLON; }
"("                       { last_token = LPAREN; return LPAREN; }
")"                       { last_token = RPAREN; return RPAREN; }

"+-"                      { /* special case: "+-" is a single invalid token, not two operators */
                            invalid_token_seen = 1;
                            strcpy(invalid_token_text, "+-");
                            return INVALID; 
                          }
.                         { /* catch-all for any other invalid character */
                            /* always update invalid_token_text - this is what's causing the error */
                            /* single char tokens like ":" take precedence over numbers like "24" */
                            invalid_token_seen = 1;
                            strncpy(invalid_token_text, yytext, sizeof(invalid_token_text) - 1);
                            invalid_token_text[sizeof(invalid_token_text) - 1] = '\0';
                            return INVALID; 
                          }

%%

