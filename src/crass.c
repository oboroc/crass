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

void scan_file(FILE* f)
{
	/* use reentrant scanner */
	yyscan_t scanner;
	yylex_init(&scanner);
	yyset_in(f, scanner);
	yylex(scanner);
	yylex_destroy(scanner);
}

int main(int argc, char** argv)
{
//	scan_str("0abch A 1 0.1 equ");
	for (int i = 1; i < argc; i++)
	{
		printf("Argument #%d = %s\n", i, argv[i]);
		FILE* f;
		errno_t err = fopen_s(&f, argv[i], "r");
		if (err != 0)
		{
			fprintf(stderr, "ERROR: can't open file %s\n", argv[i]);
			exit(1);
		}
		scan_file(f);
	}
	return 0;
}
