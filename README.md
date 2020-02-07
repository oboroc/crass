# crass - a crude assembler!

Another attempt at a Z80 assembler.


## Design goals

* make code highly modular and loosely coupled
* keep syntax clean and simple. Avoid "clever" tricks, i.e. compound statements that require effort for a human to understand
* avoid using C preprocessor for anything beyond #include
* plugin-based architecture: multiple implementations of certain functionality could be used via clearly defined API
* test coverage for each function
* extensive commentary, almost as in literate programming style
* follow [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html) conventions as appropriate for C project
* use static code analyzers to look for potential problems
* use linter to enforce uniform code formatting
* avoid tabs, use Python style 2 space indent
* reference [How to C in 2016](https://matt.sh/howto-c) for good ideas

## Flex / bison links

* great explanation of [generating reentant parsers with flex/bison](https://stackoverflow.com/questions/48850242/thread-safe-reentrant-bison-flex),
[local copy](doc/thread-safe-reentrant-bison-flex.md)
* [a sample CMakeLists.txt](https://boringssl.googlesource.com/boringssl/+/version_for_cocoapods_2.0/CMakeLists.txt)
* LUV [lex](https://luv.asn.au/overheads/lex_yacc/lex.html) and [yacc](https://luv.asn.au/overheads/lex_yacc/yacc.html) tutorial
* [Parsing arithmetic expressions - Bison and Flex](http://www-h.eng.cam.ac.uk/help/tpl/languages/flexbison/)
* Jonathan Engelsma lex/yacc video tutorial:
[lex](https://www.youtube.com/watch?v=54bo1qaHAfk) and
[yacc](https://www.youtube.com/watch?v=__-wUHG2rfM)
* [Mozilla regexp reference](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/RegExp)
* [MSDN regexp reference](https://msdn.microsoft.com/en-us/library/az24scfc%28v=vs.110%29.aspx)
* [Interactive regex tester](https://regex101.com)

## Z80 opcode links

* [Z80 info](http://z80.info/)
* [Z80 opcode tables #1](http://clrhome.org/table/)
* [Z80 opcode tables #2](http://z80-heaven.wikidot.com/opcode-reference-chart)

## File formats

* [Microsoft M80 rel format](https://seasip.info/Cpm/rel.html)
