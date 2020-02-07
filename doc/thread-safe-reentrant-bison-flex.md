Original is [here](https://stackoverflow.com/questions/48850242/thread-safe-reentrant-bison-flex),
all copyrights belongs to [rici](https://stackoverflow.com/users/1566221/rici)

# 1. Sample code

A kind of explanation of how reentrancy is configured into bison and flex is provided in section 2
of this answer. Other annotations of the sample code are in section 3.

## 1.1 eval.l
```
%option noinput nounput noyywrap 8bit nodefault                                 
%option yylineno
%option reentrant bison-bridge bison-locations                                  

%{
  #include <stdlib.h>                                                           
  #include <string.h>
  #include "eval.tab.h"                                                   

  #define YY_USER_ACTION                                             \
    yylloc->first_line = yylloc->last_line;                          \
    yylloc->first_column = yylloc->last_column;                      \
    if (yylloc->last_line == yylineno)                               \
      yylloc->last_column += yyleng;                                 \
    else {                                                           \
      yylloc->last_line = yylineno;                                  \
      yylloc->last_column = yytext + yyleng - strrchr(yytext, '\n'); \
    }
%}                                                                              
%%
[ \t]+            ;                                                  
#.*               ;                                                  

[[:digit:]]+      *yylval = strtol(yytext, NULL, 0); return NUMBER;  

.|\n              return *yytext;  
```

## 1.2 eval.y
```
%define api.pure full
%locations
%param { yyscan_t scanner }

%code top {
  #include <stdio.h>
} 
%code requires {
  typedef void* yyscan_t;
}
%code {
  int yylex(YYSTYPE* yylvalp, YYLTYPE* yyllocp, yyscan_t scanner);
  void yyerror(YYLTYPE* yyllocp, yyscan_t unused, const char* msg);
}

%token NUMBER UNOP
%left '+' '-'
%left '*' '/' '%'
%precedence UNOP
%%
input: %empty
     | input expr '\n'      { printf("[%d]: %d\n", @2.first_line, $2); }
     | input '\n'
     | input error '\n'     { yyerrok; }
expr : NUMBER
     | '(' expr ')'         { $$ = $2; }
     | '-' expr %prec UNOP  { $$ = -$2; }
     | expr '+' expr        { $$ = $1 + $3; }
     | expr '-' expr        { $$ = $1 - $3; }
     | expr '*' expr        { $$ = $1 * $3; }
     | expr '/' expr        { $$ = $1 / $3; }
     | expr '%' expr        { $$ = $1 % $3; }

%%

void yyerror(YYLTYPE* yyllocp, yyscan_t unused, const char* msg) {
  fprintf(stderr, "[%d:%d]: %s\n",
                  yyllocp->first_line, yyllocp->first_column, msg);
}
```

## 1.3 eval.h

See 3.1 for an explanation of the need for this file.

```
#include "eval.tab.h"
#include "eval.lex.h"
```

## 1.4 main.c
```
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "eval.h"
#if !YYDEBUG
  static int yydebug;
#endif

int main(int argc, char* argv[]) {
  yyscan_t scanner;          
  yylex_init(&scanner);

  do {
    switch (getopt(argc, argv, "sp")) {
      case -1: break;
      case 's': yyset_debug(1, scanner); continue;
      case 'p': yydebug = 1; continue;
      default: exit(1);
    }
    break;
 } while(1);

  yyparse(scanner);          
  yylex_destroy(scanner);    
  return 0;
}
```

## 1.5 Makefile
```
all: eval

eval.lex.c: eval.l
        flex -o $@ --header-file=$(patsubst %.c,%.h,$@) --debug $<

eval.tab.c: eval.y
        bison -o $@ --defines=$(patsubst %.c,%.h,$@) --debug $<

eval: main.c eval.tab.c eval.lex.c eval.h
        $(CC) -o $@ -Wall --std=c11 -ggdb -D_XOPEN_SOURCE=700 $(filter %.c,$^)

clean:
        rm -f eval.tab.c eval.lex.c eval.tab.h eval.lex.h main
```

# 2. Re-entrancy issues

The most important thing to remember is that Bison/Yacc and Flex/Lex are two
independent code generators. While they are frequently used together,
this is not necessary; either one can be used by itself or with other tools.

**Note**: The following discussion only applies to normal "pull" parsers.
Bison can generate push parsers (similar to Lemon) and that allows a useful
control flow inversion, which actually simplifies several of the issues mentioned below.
In particular, it completely avoids the circular dependency analysed in 3.1.
I usually prefer push parsers, but they seemed out of scope for this particular question.

## 2.1 Bison / Yacc re-entrancy

A Bison/Yacc generated parser is called once to parse an entire body of text,
so it has no need to maintain mutable persistent data objects between calls.
It does rely on a number of tables which guide the progress of the parser,
but the fact that these immutable tables have static lifetime does not affect re-entrancy.
(With Bison, at least, these tables do not have external linkage but of course
they are still visible by user-written code inserted into the parser.)

The main issue, then, are the externally-visible mutable globals yylval and yylloc,
used to augment the parser-lexer interface. These globals are definitely part of Bison/Yacc;
Flex-generated code does not even mention them, and all use of them is explicitly performed
in user actions in the Flex definition files. To make a bison parser re-entrant, it is
necessary to modify the API which the parser uses to collect information from the lexer
about each token, and the solution adopted by Bison is the classic one of providing additional
parameters which are pointers to the data structures being "returned" to the parser.
So this re-entrancy requirement changes the way the Bison-generated parser calls ```yylex;```
instead of invoking
```
int yylex(void);
```
the prototype becomes either:
```
int yylex(YYSTYPE* yylvalp);
```
or
```
int yylex(YYSTYPE* yylvalp, YYLTYPE* yyllocp);
```
depending on whether or not the parser requires the location information stored in yylloc.
(Bison will automatically detect use of location information in actions, but you can also
insist that a location object be provided to ```yylex```.)

That means that the scanner must be modified in order to correctly communicate with a
re-entrant bison parser, even if the lexer itself is not re-entrant. (See below.)

There are a small number of additional Bison/Yacc variables which are intended
for use by user code, which might force source code changes if used:

* ```yynerrs``` counts the number of syntax errors which have been encountered;
with a re-entrant parser, yynerrs is local to the yyparse and therefore can only be
used in actions. (In legacy applications, it is sometimes referenced by yyparse's caller;
such uses need to be modified for re-entrant parsers.)

* ```yychar``` is the token type of the lookahead symbol, and is sometimes used in
error reporting. In a re-entrant parser, it is local to yyparse so if it is needed by
an error reporting function, it will have to be passed explicitly.

* ```yydebug``` controls whether a parse trace is produced, if debugging code has been enabled.
```yydebug``` is still global in a re-entrant parser, so it is not possible to enable debugging
traces only for a single parser instance. (I regard this as a bug, but it could be considered
a feature request.)

* Debugging code is enabled by defining the preprocessor macro ```YYDEBUG```
or by using the ```-t``` command-line flag. These are defined by Posix; Flex also provides the
```--debug``` command line flag; the ```%debug``` directive and the
```parse.trace``` configuration directive (which can set with -Dparse.trace on the bison command line.)

## 2.2 Flex / Lex re-entrancy

```yylex``` is called repeatedly over the course of the parse; each time it is called, it returns
a single token. It needs to maintain a large amount of persistent state between calls, including its
current buffer and various pointers tracking lexical progress.

In a default lexer, this information is kept in a global struct which is not intended to be referenced
by user code, except for specific global variables (which are mostly macros in modern Flex templates).

In a re-entrant lexer, all of Flex's persistent information is collected into an opaque data structure
pointed to by a variable of type ```yyscan_t```. This variable must be passed to every call to Flex
functions, not just ```yylex```. (The list includes, for example, the various buffer management functions.)
The Flex convention is that the persistent state object is always the *last* argument to a function.
Some globals which have been relocated into this data structure have associated macros, so that
it is possible to refer to them by their traditional names Flex actions. Outside of ```yylex```,
all accesses (and modifications, in the case of mutable variables) must be done with
getter and setter functions documented in the
[Flex manual](https://westes.github.io/flex/manual/Reentrant-Functions.html).
Obviously, the list of getter/setter functions does not include accessors
for *Bison* variables, such as ```yylval```.

So ```yylex``` in a re-entrant scanner has the prototype
```
int yylex(yystate_t state);
```

## 2.3 Communication between parser and scanner

Flex/lex itself only recognizes tokens; it is up to the user action associated with each pattern
to communicate the result of the match. Conventionally, parsers expect that ```yylex``` will return
a small integer representing the token's syntactic type or 0 to indicate that the end of input
has been reached. The token's text is stored in the variable (or ```yyscan_t``` member) ```yytext```
(and its length in ```yyleng```) but since ```yytext``` is a pointer to an internal buffer
in the generated scanner, the string value can only be used before the next call to ```yylex```.
Since LR parsers do not generally process semantic information until several tokens have been read,
```yytext``` is not an appropriate mechanism for passing semantic information.

As mentioned above, non-reentrant Bison/Yacc generated parsers provide assume the use of
the global ```yylval``` to communicate semantic information, as well as the ```yylloc``` global
to communicate source location information, if that is desired (Bison only).

But, as noted above, in a re-entrant parser these variables are local to ```yyparse``` and
the parser passes pointers to the variables on each call to the lexer. This requires changes to the
prototype of ```yylex```, as well as to any scanner actions which use ```yylval```
and/or ```yylloc```.

The prototype expected by a reentrant bison-generated parser is:
```
int yylex(YYSTYPE* yylvalp, YYLTYPE* yyllocp, yystate_t state);
```
(If locations are not used, the ```yyllocp``` argument is eliminated.)

Flex's ```%bison-bridge``` directive (or the combination of ```%bison-bridge``` and
```%bison-locations``` if location tracking is being used) will ensure that the ```yylex```
prototype is correct.

All references to ```yylval``` in scanner actions also need to be modified, since bison's
reentrant API passes pointers to the semantic value and location objects.
If the semantic type is a ```union``` (normally produced by placing a ```%union``` declaration
in the bison source), then you'll need to change scanner actions which use ```yylval.tag```
to ```yylval->tag```. Similarly, if you use a single semantic type, either the default type or
one declared (in the bison source) with ```%define api.value.type```, then you'll need to
replace ```yylval = ...``` with ```*yylval = ...```, as in the sample code above.

# 3. Notes on the sample code

## 3.1. Circular header dependency

Given the above, it is impossible to declare ```yylex()``` until ```YYSTYPE``` has been declared.
Also it is impossible to declare ```yyparse()``` until ```yyscan_t``` has been declared.
Since ```yylex``` and ```yyscan_t``` are in the flex-generated header and
```yyparse``` and ```YYSTYPE``` are in the bison-generated header, neither inclusion order
for the two headers can work. Or, to put it another way, there is a circular dependency.

Since ```yyscan_t``` is just a type alias for ```void*``` (rather than being a pointer to an
incomplete type, which is arguably a cleaner way of passing pointers to opaque datastructures),
the cycle can be broken by inserting a redundant ```typedef```:

```
typedef void* yyscan_t;
#include "flex.tab.h"
#include "flex.lex.h"
```

That works fine. The next step would appear to be to put both the ```typedef``` and the
second ```#include``` inside the bison-generated header ```flex.tab.h```, using a
```code requires``` block to put the ```typedef``` near the beginning and a
```code provides``` block to put the ```#include``` near the end (or at least after the
```YYSTYPE``` declaration). Unfortunately, that does not work, because ```flex.tab.h```
is included in the flex-generated scanner code. That would have the result of including the
flex-generated header into the flex-generated source code, and that is not supported.
(Although the flex-generated header does have a header guard, the generated
source file does not require the header file to exist, so it contains a copy of the contents
rather than an ```#include``` statement, and the copy does not include the header guard.)

In the sample code, I did the next best thing: I used a ```code requires``` block to
insert the ```typedef``` into the bison-generated header, and created an additional
```eval.h``` header file which can be used by other translation units which includes the
bison- and flex-generated headers in the correct order.

That's ugly. Other solutions have been proposed, but they are all, IMHO, equally ugly.
This just happens to be the one which I use.

## 3.2. Source locations

Both the ```yylex``` and ```yyerror``` prototypes vary depending on whether or not
source locations are required by the parser. Since these changes will reverberate through the
various project files, I think that the most advisable is to force the usage of
location information, even if it is not (yet) being used by the parser. Someday you might want
to use it, and the runtime overhead of maintaining it is not enormous (although it is
measurable, so you might want to ignore this advice in resource-constrained environments).

To simplify the load, I include a simple general implementation in lines 10-17 of ```flex.l```
which uses on the ```YY_USER_ACTION``` to insert code at the beginning of all flex rule actions.
This ```YY_USER_ACTION``` macro should work for any scanner which does not use
```yyless()```, ```yymore()```, ```input()``` or ```REJECT```. Correctly coping with these
features is not too difficult but it seemed out of scope here.

## 3.3 Bison error recovery

Bison and Yacc generated parsers follow the Posix requirement that debugging code in the
generated source is not compiled unless the preprocessor macro ```YYDEBUG``` is defined and
has a non-zero value. If debugging code is compiled into the binary, then debugging traces are
controlled by the global variable ```yydebug```. If ```YYDEBUG``` is non-zero,
```yydebug``` is given a default value of 0, which disables traces. If ```YYDEBUG``` is 0,
```yydebug``` is not defined by the bison/yacc-generated code. If ```YYDEBUG``` is not defined,
then it will be defined by the generated code, with value 0 unless the ```-t``` command-line
option is used, in which case it will have default value 1.

Bison inserts the ```YYDEBUG``` macro definition into the generated header file
(although it is not obliged by Posix to do so), so I test for it in ```main.c``` and
provide an alternative definition of the ```yydebug``` variable if it has not been defined.
This allows the code which enables debugging traces to compile even if it is
not going to be able to turn on tracing.

Flex-generated code normally uses the global variable ```yy_flex_debug``` to turn traces
on and off; unlike yacc/bison, the default value of ```yy_flex_debug``` is 1 if debugging code
is compiled into the executable. Since a reentrant scanner cannot use global variables,
the reentrant scanner puts the debug enabler into the ```yyscan_t``` object, where it can be
accessed with the ```yyset_debug``` and ```yyget_debug``` access functions, which are defined
whether or not debugging code has been compiled. However, the default value of the re-entrant
debugging flag is 0, so if you create a reentrant scanner, you need to explicitly
enable tracing even if tracing has been compiled into the executable.
(This makes a reentrant scanner more like a parser.)

The sample ```main``` program turns on scanner tracing if run with the ```-s```
command-line option, and parser tracing with the ```-sp``` option.
