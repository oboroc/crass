/*
 * crass - a crude assembler!
 */

#include <stdio.h>
#include <assert.h>
#include <string.h>

extern FILE* yyin, * yyout;
extern int yylex(void);

int yywrap(void)
{
	return 1;
}

int main(int argc, char** argv)
{
	++argv, --argc;	/* skip over program name */
	if (argc > 0)
	{
		errno_t err;
		err = fopen_s(&yyin, argv[0], "r");
		if (err != 0)
		{
			fprintf(stderr, "ERROR: can't open the file %s\n", argv[0]);
			exit(1);
		}
	}
	else
		yyin = stdin;

	yylex();
}
