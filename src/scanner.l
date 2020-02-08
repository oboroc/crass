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

%option noyywrap
%option caseless reentrant yylineno
%option batch align 8bit fast read
%option warn backup verbose
%option nodefault
%option outfile="scanner.flex.c" header-file="scanner.flex.h"
%option prefix="crass"

%x incl str

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

	/* string matcher usign exclusive condition, inspired by:
	https://westes.github.io/flex/manual/Start-Conditions.html#Start-Conditions */

\"	BEGIN(str);

<str>\n {
	fprintf(stderr, "ERROR: string not terminated before the new line: %s\n", yytext);
}

<str><<EOF>> {
	fprintf(stderr, "ERROR: string not terminated before the end of file: %s\n", yytext);
}

<str>[^\"]* {
	printf("A string: \"%s\"\n", yytext);
}

<str>\" {
	BEGIN(INITIAL);
}

<str>. {
	fprintf(stderr, "ERROR: fall through in <str> condition: %s\n", yytext);
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
	fprintf(stderr, "ERROR: invalid token: %s\n", yytext);
}

	/* rule for simple float */
[0-9]+"."[0-9]+ {
	printf("A float: %s (%g)\n", yytext, atof(yytext));
}

	/* eliminate backing up by capturing '1.' */
[0-9]+"." {
	fprintf(stderr, "ERROR: invalid token: %s\n", yytext);
}

	/* eliminate backing up by capturing '.1' */
"."[0-9]+ {
	fprintf(stderr, "ERROR: invalid token: %s\n", yytext);
}

"+"	|
"-"	|
"*"	|
"/" {
	printf("An operator: %s\n", yytext);
}

	/* reserved words */
end		|
equ		|
org {
	printf("A keyword: %s\n", yytext);
}

	/* opcodes */
ld		|	/* load */

ex		|	/* exchange */
exx		|

push	|	/* stack */
pop		|

add		|	/* arithmetic */
adc		|
sub		|
sbc		|
cp		|
inc		|
dec		|

jp		|	/* jumps and return */
jr		|
djnz	|
call	|
ret		|
reti	|
retn	|

and		|	/* boolean logic */
or		|
xor		|

set		|	/* bit set, reset and test */
res		|
bit		|

rlca	|	/* rotate */
rla		|
rrca	|
rra		|
rlc		|
rl		|
rrc		|
rr		|
rld		|
rrd		|

sla		|	/* shift */
sra		|
srl		|

nop		|	/* general */
halt	|
di		|
ei		|
im		|
scf		|
ccf		|
neg		|
cpl		|
daa		|

ldi		|	/* block transfer */
ldd		|
ldir	|
lddr	|

cpi		|	/* block search */
cpd		|
cpir	|
cpdr	|

otdr	|	/* io */
otir	|
outd	|
outi	|
out		|
indr	|
inir	|
ind		|
ini		|
in {
	printf("An opcode: %s\n", yytext);
}

[a-z_][a-z0-9_]* {
	printf("An identifier: %s\n", yytext);
}

[ \t\n]+	/* eat up whitespace */

";".*		/* MASM style comment: starts with ; and ends with new line or end of file */

<*>.|\n {
	/* default action, should always be the last */
	fprintf(stderr, "ERROR: Flex default rule fall-through: \"%s\" - please create new rules to capture this input\n", yytext);
}

%%
