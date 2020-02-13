/* Infix notation calculator. */

%{
	#include <math.h>
	#include <stdio.h>
	#include "scanner.flex.h"
    void yyerror(char const*);
%}


/* Bison declarations. */
%define api.pure full
//%define parse.error verbose
//%define api.value.type {double}
%define api.prefix {crass}

%union
{
	int num;
	double fp;
	char *str;
}

%token <num> NOP


%%	/* The grammar follows */

input:
	%empty
|	input line
;


line:
	'\n'
|	exp '\n'	{ printf("blah\n"); }
;

exp:
	NOP
	;

%%

void yyerror(char const* s)
{
	fprintf(stderr, "%s\n", s);
}
