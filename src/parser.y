/* Infix notation calculator. */

%{
	#include <math.h>
	#include <stdio.h>
	#include "scanner.flex.h"
	//int yylex(void);
	void yyerror(char const *);
%}


/* Bison declarations. */
%define api.pure full
//%define parse.error verbose
%define api.value.type {double}
//%define api.prefix {crass}

%token NUM
%left '-' '+'
%left '*' '/'
%precedence NEG		/* negation--unary minus */
%right '^'			/* exponentiation */


%%	/* The grammar follows */

input:
	%empty
|	input line
;


line:
	'\n'
|	exp '\n'	{ printf ("\t%.10g\n", $1); }
;


exp:
	NUM
|	exp '+' exp	{ $$ = $1 + $3; }
|	exp '-' exp	{ $$ = $1 - $3; }
|	exp '*' exp	{ $$ = $1 * $3; }
|	exp '/' exp	{ $$ = $1 / $3; }
|	'-' exp  %prec NEG	{ $$ = -$2; }
|	exp '^' exp	{ $$ = pow ($1, $3); }
|	'(' exp ')'	{ $$ = $2; }
;

%%



void yyerror(char const *s)
{
	fprintf (stderr, "%s\n", s);
}

