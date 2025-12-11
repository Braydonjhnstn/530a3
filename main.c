#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yyparse(void);
extern FILE *yyin;
extern int yylineno;
extern int parse_error;
extern char error_message[256];
extern int invalid_token_seen;
extern char invalid_token_text[256];
extern int last_token;
extern int op_op_error;

int main(int argc, char *argv[]) {
    FILE *input_file;
    char *filename = "scanme.txt";
    char line[1024];
    
    // Check for user-specified filename
    if (argc > 1) {
        filename = argv[1];
    }
    
    // Open input file
    input_file = fopen(filename, "r");
    if (input_file == NULL) {
        fprintf(stderr, "Error: Cannot open file '%s'\n", filename);
        return 1;
    }
    
    // Process each line
    while (fgets(line, sizeof(line), input_file) != NULL) {
        // Store original line length (including newline and trailing spaces)
        size_t original_len = strlen(line);
        
        // Create a working copy for parsing (remove newline for parsing only)
        char working_line[1024];
        strncpy(working_line, line, sizeof(working_line) - 1);
        working_line[sizeof(working_line) - 1] = '\0';
        size_t len = strlen(working_line);
        if (len > 0 && working_line[len-1] == '\n') {
            working_line[len-1] = '\0';
        }
        
        // Skip empty lines
        if (strlen(working_line) == 0) {
            continue;
        }
        
        // Reset parser state
        parse_error = 0;
        error_message[0] = '\0';
        invalid_token_seen = 0;
        invalid_token_text[0] = '\0';
        last_token = 0;
        op_op_error = 0;
        yylineno = 1;
        
        // Create a temporary file for this line
        FILE *temp_file = tmpfile();
        if (temp_file == NULL) {
            fprintf(stderr, "Error: Cannot create temporary file\n");
            continue;
        }
        
        fprintf(temp_file, "%s\n", working_line);
        rewind(temp_file);
        
        // Pre-scan the line to detect "op op" errors and prioritize certain invalid tokens
        // This needs to happen before parsing so we can prioritize op op over invalid tokens
        // Also check for ":" which should be reported over numbers like "24"
        char *colon_pos = strchr(working_line, ':');
        if (colon_pos != NULL) {
            // If we find ":", prioritize reporting it over numbers
            invalid_token_text[0] = ':';
            invalid_token_text[1] = '\0';
            invalid_token_seen = 1;
        }
        
        char *p = working_line;
        int prev_was_op = 0;
        while (*p) {
            // Skip whitespace
            while (*p == ' ' || *p == '\t' || *p == '\r') p++;
            if (!*p) break;
            
            // Check for "+-" as a single invalid token (not two operators)
            if (*p == '+' && *(p+1) == '-' && (*(p+2) == ' ' || *(p+2) == '\t' || *(p+2) == '\r' || *(p+2) == '\0')) {
                // This is "+-" invalid token, not op op
                prev_was_op = 0;
                p += 2;
                continue;
            }
            
            // Check if current char is an operator
            if (*p == '+' || *p == '-' || *p == '*' || *p == '/' || *p == '%' || *p == '=') {
                if (prev_was_op) {
                    op_op_error = 1;
                    break;
                }
                prev_was_op = 1;
                p++;
            } else if (*p == '(' || *p == ')' || *p == ';') {
                prev_was_op = 0;
                p++;
            } else {
                // Skip identifier or invalid token
                while (*p && *p != ' ' && *p != '\t' && *p != '\r' && 
                       *p != '+' && *p != '-' && *p != '*' && *p != '/' && 
                       *p != '%' && *p != '=' && *p != '(' && *p != ')' && *p != ';') {
                    p++;
                }
                prev_was_op = 0;
            }
        }
        
        // Set yyin to the temporary file and restart lexer
        yyin = temp_file;
        extern void yyrestart(FILE *);
        yyrestart(yyin);
        
        // Parse the statement
        int result = yyparse();
        
        // Prepare line for printing: preserve original content but remove newline/carriage return
        // Create a copy to avoid modifying the original
        char print_line[1024];
        strncpy(print_line, line, sizeof(print_line) - 1);
        print_line[sizeof(print_line) - 1] = '\0';
        
        // Remove trailing newline and carriage return
        size_t print_len = strlen(print_line);
        while (print_len > 0 && (print_line[print_len-1] == '\n' || print_line[print_len-1] == '\r')) {
            print_line[print_len-1] = '\0';
            print_len--;
        }
        
        // Trim leading spaces for display (but we parsed the full line)
        char *display_line = print_line;
        while (*display_line == ' ' || *display_line == '\t') {
            display_line++;
        }
        
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
        
        // Clean up
        fclose(temp_file);
    }
    
    fclose(input_file);
    return 0;
}

