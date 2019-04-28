/*
wip scanner
http://people.cs.aau.dk/~marius/sw/flex/Flex-Regular-Expressions.html - useful
 */


%{
/* need this for the call to atof() below */
#include <math.h>
#include <assert.h>
%}

%option caseless

DIGIT	[0-9]
ID		[a-z_][a-z0-9_]*

%%

{DIGIT}+	{
				printf("An integer: %s (%d)\n", yytext,
					atoi(yytext));
			}

{DIGIT}*"."{DIGIT}+	{
				printf("A float: %s (%g)\n", yytext,
					atof(yytext));
			}

if|then|begin|end|procedure|function	{
				printf("A keyword: %s\n", yytext);
			}

{ID}		printf("An identifier: %s\n", yytext);

"+"|"-"|"*"|"/"	printf("An operator: %s\n", yytext);

"{"[^{}\n]*"}"	/* eat up one-line comments */

[ \t\n]+	/* eat up whitespace */

.			printf("Unrecognized character: %s\n", yytext);

%%
