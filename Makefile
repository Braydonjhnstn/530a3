# Makefile for CS530 Assignment 3
# Student Name: [Your Name]
# RedID: [Your RedID]
# Tool versions: flex 2.6.1, bison 3.0.4, gcc 8.5.0, make 4.2.1

CC = gcc
CFLAGS = -Wall -g
LEX = flex
YACC = bison
YFLAGS = -d

# Executable name must be 'scanner'
TARGET = scanner

# Source files
LEX_SRC = scanner.l
YACC_SRC = parser.y
MAIN_SRC = main.c

# Generated files
LEX_C = lex.yy.c
YACC_C = parser.tab.c
YACC_H = parser.tab.h

# Object files
OBJS = $(LEX_C:.c=.o) $(YACC_C:.c=.o) $(MAIN_SRC:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS) -ll

$(LEX_C): $(LEX_SRC) $(YACC_H)
	$(LEX) $(LEX_SRC)

$(YACC_C) $(YACC_H): $(YACC_SRC)
	$(YACC) $(YFLAGS) $(YACC_SRC)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) $(OBJS) $(LEX_C) $(YACC_C) $(YACC_H)

.PHONY: all clean

