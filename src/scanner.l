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

%%

[0-9]+ {
	printf("An integer: %s (%d)\n", yytext, atoi(yytext));
}

[0-9]*"."[0-9]+ {
	printf("A float: %s (%g)\n", yytext, atof(yytext));
}

[0-9][0-9a-f]*h {
	printf("A hexadecimal: %s (%x)\n", yytext, strtol(yytext, NULL, 16));
}

equ|ifdef|else|endif {
	printf("A keyword: %s\n", yytext);
}

[a-z_][a-z0-9_]* {
	printf("An identifier: %s\n", yytext);
}

"+"|"-"|"*"|"/" {
	printf("An operator: %s\n", yytext);
}

[ \t\n]+	/* eat up whitespace */

. {
	printf("Unrecognized character: %s\n", yytext);
}

"/*"			BEGIN(C_COMMENT);
<C_COMMENT>.	/* skip over comment */
<C_COMMENT>"*/"	BEGIN(INITIAL);

";".*		/* MASM style comment: starts with ; and ends with new line */

%%
