/*
 * crass - a crude assembler!
 */

#include <stdio.h>
#include <assert.h>
#include <string.h>

#include "scanner.flex.h"

#define UNUSED(x) (void)(x)

int yywrap(yyscan_t yyscanner)
{
	UNUSED(yyscanner);
	return 1;
}

void scan_str(char *str)
{
	/* use reentrant scanner */
	yyscan_t scanner;
	YY_BUFFER_STATE buf;
	yylex_init(&scanner);
	buf = yy_scan_string(str, scanner);
	yylex(scanner);
	yy_delete_buffer(buf, scanner);
	yylex_destroy(scanner);
}

int main(int argc, char** argv)
{
	UNUSED(argc);
	UNUSED(argv);
	scan_str("0abch 01234h 0ffffh");
	scan_str("A B C");
	scan_str("0.1 .2 1.0003");
	scan_str("equ");
	return 0;
}
