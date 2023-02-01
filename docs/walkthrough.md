# Walkthrough

This document attempts to describe Fennec syntax in plain english, starting from top level constructions and moving down the syntax tree.

### Terminology

- Declarations are syntax constructions that can only be used at the root level. They can have effects on any other part of the program. These are includes, links, arrays, function definitions, and constant definitions.
- Statements are used within functions to represent imperitive actions (ie. operations with side effects) and control flow operations (loops and conditionals). They can be sequenced together and can also be embedded within expressions using block expressions.
- Expressions are operations that give a value, which can be either passed to functions, or to statements that can use them.

## Compiler Directives

The `include <library>` declaration is used to join multiple fennec source code files together. This is done by finding the source file that `<library>` indicates, and then compiling that file's contents as if it were stitched into the original file at that position.

There is a second declaration that can be used, although it only has an effect if the compiler is also going to perform linking. The `link <source>` declaration indicates a file that should be linked with the root file that is being compiled, and compiled too if it is not already.

The compiler figures out which files to include or link through command line arguments that are passed to it, which can either indicate direct conversions or list directories to search within.

```
include "stdlib"
link "other_file.fen"
```

## Constants

Constants are named values that don't change from compile time. To define one, use `constant <name> = <value>`, where value is either a number, a string, or an existing constant. Constants are declarations and can only be defined at the root level. They can be used in expressions, but also in places such as array sizes or library names.

```
constant LETTER_A = 65
constant MAGIC_NUMBER = 0xBADBEEF
constant SECOND_LETTER_A = LETTER_A
constant HELLOWORLD_STRING = "Hello World!"
```

## Arrays

*todo*

## Declaring functions

*todo*

## Basic statements

*todo*

## Assignment Statements

*todo*

## Loops and Conditionals

*todo*

## Function calls

*todo*
