/*
wip scanner

TODO: externalize rule code as per https://westes.github.io/flex/manual/Accessor-Methods.html
TODO: evaluate flex based macro expansion: https://westes.github.io/flex/manual/How-can-I-expand-macros-in-the-input_003f.html
TODO: use https://westes.github.io/flex/manual/Common-Patterns.html for basic patterns
 */

%top {
/* This code goes at the top of the generated file */
#include <stdint.h>
#include <inttypes.h>
#include <math.h>
#include <assert.h>
}

%{
%}

%option caseless reentrant yylineno
%option batch align 8bit fast read
%option warn backup verbose
%option nodefault
%option outfile="scanner.flex.c" header-file="scanner.flex.h"
%option prefix="crass"

%x incl

%%

include			BEGIN(incl);

<incl>[ \t]*	/* eat the whitespace in include mode */

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

	/* rule for binary numbers */
[0-1]+b {
	printf("A binary number: %s (%d)\n", yytext, strtol(yytext, NULL, 2));
}

	/* https://westes.github.io/flex/manual/Performance.html#index-error-rules_002c-to-eliminate-backing-up */
[0-9][0-9a-f]*h {
	printf("A hexadecimal: %s (%x)\n", yytext, strtol(yytext, NULL, 16));
}

	/* eliminate backing up for the hexadecimal rule above */
[0-9][0-9a-f]* {
	fprintf(stderr, "Invalid token: %s\n", yytext);
}

	/* rule for simple float */
[0-9]+"."[0-9]+ {
	printf("A float: %s (%g)\n", yytext, atof(yytext));
}

	/* eliminate backing up by capturing '1.' */
[0-9]+"." {
	fprintf(stderr, "Invalid token: %s\n", yytext);
}

	/* eliminate backing up by capturing '.1' */
"."[0-9]+ {
	fprintf(stderr, "Invalid token: %s\n", yytext);
}

"+"	|
"-"	|
"*"	|
"/" {
	printf("An operator: %s\n", yytext);
}

equ		|
ifdef	|
else	|
endif {
	printf("A keyword: %s\n", yytext);
}

[a-z_][a-z0-9_]* {
	printf("An identifier: %s\n", yytext);
}

[ \t\n]+	/* eat up whitespace */

";".*		/* MASM style comment: starts with ; and ends with new line or end of file */

<*>.|\n {
	/* default action, should always be the last */
	fprintf(stderr, "Flex default rule fall-through: \"%s\" - please create new rules to capture this input\n", yytext);
}

%%
