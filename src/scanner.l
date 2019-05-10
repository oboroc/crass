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

%option caseless reentrant yylineno

%x incl

%%

include			BEGIN(incl);

<incl>[ \t]*	/* eat the whitespace */

<incl>[^ \t\n]+ {
	/* got the include file name */
	errno_t err = fopen_s(&yyin, yytext, "r");
	if (err != 0)
	{
		fprintf(stderr, "ERROR: can't open include file %s\n", yytext);
		exit(1);
	}
	yypush_buffer_state(yy_create_buffer(yyin, YY_BUF_SIZE, yyscanner), yyscanner);
	BEGIN(INITIAL);
}

<<EOF>> {
	yypop_buffer_state(yyscanner);
	if (!YY_CURRENT_BUFFER)
		yyterminate();
}

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

";".*		/* MASM style comment: starts with ; and ends with new line */

%%
