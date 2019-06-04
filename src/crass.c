/*
 * crass - a crude assembler!
 */

#include <stdio.h>
#include <assert.h>
#include <string.h>

#include "scanner.flex.h"

#define UNUSED(x) (void)(x)

int crasswrap(yyscan_t yyscanner)
{
	UNUSED(yyscanner);
	return 1;
}

void scan_str(char *str)
{
	/* use reentrant scanner */
	yyscan_t scanner;
	YY_BUFFER_STATE buf;
	crasslex_init(&scanner);
	buf = crass_scan_string(str, scanner);
	crasslex(scanner);
	crass_delete_buffer(buf, scanner);
	crasslex_destroy(scanner);
}

void scan_file(FILE* f)
{
	/* use reentrant scanner */
	yyscan_t scanner;
	crasslex_init(&scanner);
	crassset_in(f, scanner);
	crasslex(scanner);
	crasslex_destroy(scanner);
}

int main(int argc, char** argv)
{
	if (argc < 2)
	{
		fprintf(stderr, "ERROR: please provide an input file to process\n");
		exit(1);
	}
	scan_str("0abch A 1 0.1 equ \"abc\" ahaha");
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
