/*
##
## main.c
## Name: Braydon Johnston REDid: 131049942 Class Acc: cssc2115
## Assignment 3
## CS530-03 Fall 2025
##
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// external functions and variables from the parser
extern int yyparse(void);              // bison parser function
extern FILE *yyin;                     // input file for lexer
extern int yylineno;                   // current line number
extern int parse_error;                // flag set when parse error occurs
extern char error_message[256];        // error message string
extern int invalid_token_seen;         // flag for invalid token detection
extern char invalid_token_text[256];   // text of invalid token
extern int last_token;                 // last token type seen (for op op detection)
extern int op_op_error;                // flag for consecutive operator error

int main(int argc, char *argv[]) {
    FILE *input_file;
    char *filename = "scanme.txt";  // default input file
    char line[1024];
    
    // check if user provided a filename, use it if they did
    if (argc > 1) {
        filename = argv[1];
    }
    
    // open the input file and bail if we can't
    input_file = fopen(filename, "r");
    if (input_file == NULL) {
        fprintf(stderr, "Error: Cannot open file '%s'\n", filename);
        return 1;
    }
    
    // process each line from the input file
    while (fgets(line, sizeof(line), input_file) != NULL) {
        // keep track of original line length for printing later
        size_t original_len = strlen(line);
        
        // make a copy of the line for parsing, need to strip newline for the parser
        char working_line[1024];
        strncpy(working_line, line, sizeof(working_line) - 1);
        working_line[sizeof(working_line) - 1] = '\0';
        size_t len = strlen(working_line);
        if (len > 0 && working_line[len-1] == '\n') {
            working_line[len-1] = '\0';
        }
        
        // skip blank lines, nothing to parse
        if (strlen(working_line) == 0) {
            continue;
        }
        
        // reset all the parser state variables for this new line
        parse_error = 0;
        error_message[0] = '\0';
        invalid_token_seen = 0;
        invalid_token_text[0] = '\0';
        last_token = 0;
        op_op_error = 0;
        yylineno = 1;
        
        // create a temp file to feed to the lexer/parser
        // the parser expects to read from a file, so we write the line to a temp file
        FILE *temp_file = tmpfile();
        if (temp_file == NULL) {
            fprintf(stderr, "Error: Cannot create temporary file\n");
            continue;
        }
        
        fprintf(temp_file, "%s\n", working_line);
        rewind(temp_file);
        
        // pre-scan the line to catch "op op" errors before parsing
        // this way we can report op op instead of just invalid token
        // also check for ":" since we want to report that over numbers like "24"
        char *colon_pos = strchr(working_line, ':');
        if (colon_pos != NULL) {
            // found a colon, mark it as the invalid token to report
            invalid_token_text[0] = ':';
            invalid_token_text[1] = '\0';
            invalid_token_seen = 1;
        }
        
        // scan through the line looking for consecutive operators
        char *p = working_line;
        int prev_was_op = 0;
        while (*p) {
            // skip over whitespace
            while (*p == ' ' || *p == '\t' || *p == '\r') p++;
            if (!*p) break;
            
            // special case: "+-" is a single invalid token, not two operators
            if (*p == '+' && *(p+1) == '-' && (*(p+2) == ' ' || *(p+2) == '\t' || *(p+2) == '\r' || *(p+2) == '\0')) {
                // this is the "+-" token, not op op, so reset the flag
                prev_was_op = 0;
                p += 2;
                continue;
            }
            
            // check if we're looking at an operator
            if (*p == '+' || *p == '-' || *p == '*' || *p == '/' || *p == '%' || *p == '=') {
                if (prev_was_op) {
                    // two operators in a row, that's an op op error
                    op_op_error = 1;
                    break;
                }
                prev_was_op = 1;
                p++;
            } else if (*p == '(' || *p == ')' || *p == ';') {
                // parentheses and semicolons reset the operator flag
                prev_was_op = 0;
                p++;
            } else {
                // skip over identifiers or other tokens
                while (*p && *p != ' ' && *p != '\t' && *p != '\r' && 
                       *p != '+' && *p != '-' && *p != '*' && *p != '/' && 
                       *p != '%' && *p != '=' && *p != '(' && *p != ')' && *p != ';') {
                    p++;
                }
                prev_was_op = 0;
            }
        }
        
        // point the lexer at our temp file and reset it
        yyin = temp_file;
        extern void yyrestart(FILE *);
        yyrestart(yyin);
        
        // actually parse the statement now
        int result = yyparse();
        
        // prepare the line for printing
        // need to keep the original line but strip newlines and carriage returns
        char print_line[1024];
        strncpy(print_line, line, sizeof(print_line) - 1);
        print_line[sizeof(print_line) - 1] = '\0';
        
        // strip off trailing newline and carriage return characters
        size_t print_len = strlen(print_line);
        while (print_len > 0 && (print_line[print_len-1] == '\n' || print_line[print_len-1] == '\r')) {
            print_line[print_len-1] = '\0';
            print_len--;
        }
        
        // trim leading spaces for cleaner output (we still parsed the full line though)
        char *display_line = print_line;
        while (*display_line == ' ' || *display_line == '\t') {
            display_line++;
        }
        
        // print the line and then the validation result
        printf("%s  --  ", display_line);
        if (result == 0 && parse_error == 0) {
            printf("valid\n");
        } else {
            printf("invalid");
            if (strlen(error_message) > 0) {
                printf(": %s", error_message);
            } else {
                printf(": syntax error");
            }
            printf("\n");
        }
        
        // cleanup the temp file
        fclose(temp_file);
    }
    
    fclose(input_file);
    return 0;
}

