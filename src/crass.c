// crass.cpp: This file contains the 'main' function. Program execution begins and ends there.
//

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

	++argv, --argc;	/* skip over program name */
	if (argc > 0)
	{
		err = fopen_s(&yyin, argv[0], "r");
		assert(err == 0);
	}
	else
		yyin = stdin;

	yylex();
}
