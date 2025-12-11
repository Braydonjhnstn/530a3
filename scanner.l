%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

extern int yylval;
extern int invalid_token_seen;
extern char invalid_token_text[256];
extern int last_token;
extern int op_op_error;
%}

%option noyywrap
%option yylineno

%%

[ \t\r]+                  { /* ignore whitespace and carriage returns */ }
\n                        { return NEWLINE; }

[0-9]+[a-zA-Z][a-zA-Z0-9]* { 
                            invalid_token_seen = 1;
                            strncpy(invalid_token_text, yytext, sizeof(invalid_token_text) - 1);
                            invalid_token_text[sizeof(invalid_token_text) - 1] = '\0';
                            return INVALID; 
                          }
[0-9]+                    { 
                            // Store this invalid token, but only if we haven't already seen a better one
                            // (like ":" which was detected in pre-scan)
                            if (!invalid_token_seen) {
                                strncpy(invalid_token_text, yytext, sizeof(invalid_token_text) - 1);
                                invalid_token_text[sizeof(invalid_token_text) - 1] = '\0';
                            }
                            return INVALID; 
                          }
[a-zA-Z][a-zA-Z0-9]*      { last_token = ID; return ID; }
"+"                       { 
                            if (last_token == OP_PLUS || last_token == OP_MINUS || 
                                last_token == OP_MULT || last_token == OP_DIV || 
                                last_token == OP_MOD || last_token == ASSIGN) {
                                op_op_error = 1;
                            }
                            last_token = OP_PLUS;
                            return OP_PLUS; 
                          }
"-"                       { 
                            if (last_token == OP_PLUS || last_token == OP_MINUS || 
                                last_token == OP_MULT || last_token == OP_DIV || 
                                last_token == OP_MOD || last_token == ASSIGN) {
                                op_op_error = 1;
                            }
                            last_token = OP_MINUS;
                            return OP_MINUS; 
                          }
"*"                       { 
                            if (last_token == OP_PLUS || last_token == OP_MINUS || 
                                last_token == OP_MULT || last_token == OP_DIV || 
                                last_token == OP_MOD || last_token == ASSIGN) {
                                op_op_error = 1;
                            }
                            last_token = OP_MULT;
                            return OP_MULT; 
                          }
"/"                       { 
                            if (last_token == OP_PLUS || last_token == OP_MINUS || 
                                last_token == OP_MULT || last_token == OP_DIV || 
                                last_token == OP_MOD || last_token == ASSIGN) {
                                op_op_error = 1;
                            }
                            last_token = OP_DIV;
                            return OP_DIV; 
                          }
"%"                       { 
                            if (last_token == OP_PLUS || last_token == OP_MINUS || 
                                last_token == OP_MULT || last_token == OP_DIV || 
                                last_token == OP_MOD || last_token == ASSIGN) {
                                op_op_error = 1;
                            }
                            last_token = OP_MOD;
                            return OP_MOD; 
                          }
"="                       { 
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

"+-"                      { 
                            invalid_token_seen = 1;
                            strcpy(invalid_token_text, "+-");
                            return INVALID; 
                          }
.                         { 
                            // Always update invalid_token_text - this is the token causing the error
                            // Single character tokens like ":" take precedence over numbers like "24"
                            invalid_token_seen = 1;
                            strncpy(invalid_token_text, yytext, sizeof(invalid_token_text) - 1);
                            invalid_token_text[sizeof(invalid_token_text) - 1] = '\0';
                            return INVALID; 
                          }

%%

