/*
wip scanner
 */

%top {
/* This code goes at the "top" of the generated file. */
#include <stdint.h>
#include <inttypes.h>
#include <math.h>
#include <assert.h>
}

%{
%}

%option caseless
%x C_COMMENT

DIGIT	[0-9]
ID		[a-z_][a-z0-9_]*

%%

{DIGIT}+ {
	printf("An integer: %s (%d)\n", yytext, atoi(yytext));
}

{DIGIT}*"."{DIGIT}+ {
	printf("A float: %s (%g)\n", yytext, atof(yytext));
}

/* this isn't working for some reasons */
[0-9][0-9a-f]*h {
	
	printf("A hexadecimal: %s (%x)", yytext, strtol(yytext, NULL, 16));
}

equ|ifdef|else|endif {
	printf("A keyword: %s\n", yytext);
}

{ID}	printf("An identifier: %s\n", yytext);

"+"|"-"|"*"|"/"	printf("An operator: %s\n", yytext);

[ \t\n]+	/* eat up whitespace */

.	printf("Unrecognized character: %s\n", yytext);

"/*"			BEGIN(C_COMMENT);
<C_COMMENT>"*/"	BEGIN(INITIAL);
<C_COMMENT>.	/* eat up comment content */

";".*		/* MASM style comment: starts with ; and ends with new line */

%%
