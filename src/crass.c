/*
 * crass - a crude assembler!
 */

#include <stdio.h>
#include <assert.h>
#include <string.h>

#include "scanner.flex.h"

int yywrap(yyscan_t yyscanner)
{
	return 1;
}

int main(int argc, char** argv)
{
	/* use reentrant scanner */
	yyscan_t scanner;
	YY_BUFFER_STATE buf;
	yylex_init(&scanner);
	buf = yy_scan_string("0abch 01234h 0ffffh", scanner);
	yylex(scanner);
	yy_delete_buffer(buf, scanner);
	yylex_destroy(scanner);
	return 0;
}
