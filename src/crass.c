/*
 * crass - a crude assembler!
 */

#include <stdio.h>
#include <assert.h>

extern FILE* yyin, * yyout;
extern int yylex(void);

int yywrap(void)
{
	return 1;
}

int main(int argc, char** argv)
{
	errno_t err;

	/* skip over program name */
	argv++;
	argc--;
	if (argc > 0)
	{
		err = fopen_s(&yyin, argv[0], "r");
		assert(err == 0);
	}
	else
		yyin = stdin;

	yylex();
}
