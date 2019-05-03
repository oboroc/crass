/*
 * crass - a crude assembler!
 */

#include <stdio.h>
#include <assert.h>
#include <string.h>

extern FILE* yyin, * yyout;
extern int yylex(void);

static size_t read_pos;
static const char* input_buf = "123 abc";
int lexer_input(char* buf, int* result, int max_size)
{
	size_t total_char = max_size;
	size_t char_to_read = strlen(input_buf) - read_pos;
	int i;
	if (total_char > char_to_read)
		total_char = char_to_read;
	for (i = 0; i < total_char; i++)
		buf[i] = input_buf[read_pos + i];
	*result = total_char;
	read_pos += total_char;
	return 0;
}

int yywrap(void)
{
	return 1;
}

int main(int argc, char** argv)
{
	yylex();
}
