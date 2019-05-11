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
	#define MAX_STR_CONST 1000
	char string_buf[MAX_STR_CONST];
	char *string_buf_ptr;
%}

%option caseless reentrant yylineno

%x incl str

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

	/*. {
	//	printf("Unrecognized character: %s\n", yytext);
	}*/

";".*		/* MASM style comment: starts with ; and ends with new line */

	/* next part is a C style string matcher as per https://westes.github.io/flex/manual/Start-Conditions.html */

\" {
	string_buf_ptr = string_buf;
	BEGIN(str);
}

<str>\" {
	/* saw closing quote - all done */
	BEGIN(INITIAL);
	*string_buf_ptr = '\0';
	/* return string constant token type and value to parser */
	printf("A string: \"%s\"\n", string_buf);
}

<str>\n {
	/* error - unterminated string constant */
	/* generate error message */
	fprintf(stderr, "ERROR: a string is unterminated: %s\n", yytext);
	exit(1);
}

<str>\\[0-7]{1,3} {
	/* octal escape sequence */
	int result;
	(void)sscanf_s(yytext + 1, "%o", &result);
	if (result > 0xff)
	{
		/* error, constant is out-of-bounds */
		fprintf(stderr, "ERROR: octal constant is out of bounds\n");
		exit(1);
	}
	*string_buf_ptr++ = (char)result;
	printf("Octal value found: %s (%d)\n", yytext, result);
}

<str>\\[0-9]+ {
	/* generate error - bad escape sequence;
	something like '\48' or '\0777777' */
	fprintf(stderr, "ERROR: invalid escape sequence: %s\n", yytext);
	exit(1);
}

<str>\\n {
	*string_buf_ptr++ = '\n';
	printf("escaped lf\n");
}

<str>\\t {
	*string_buf_ptr++ = '\t';
	printf("escaped tab\n");
}

<str>\\r {
	*string_buf_ptr++ = '\r';
	printf("escaped cr\n");
}

<str>\\b {
	*string_buf_ptr++ = '\b';
	printf("escaped backspace\n");
}

<str>\\f {
	*string_buf_ptr++ = '\f';
	printf("escaped form feed\n");
}

<str>\\(.|\n) {
	*string_buf_ptr++ = yytext[1];
	printf("escaped '%c'\n", yytext[1]);
}

<str>[^\\\n\"]+ {
	/* I guess this is for unescaped, normal string characters */
	char *yptr = yytext;
	while (*yptr)
		*string_buf_ptr++ = *yptr++;
}

%%
