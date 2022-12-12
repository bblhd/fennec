# Syntax

This document describes valid Fennec syntax using EBNF according to [the variant](https://www.w3.org/TR/REC-xml/#sec-notation) used by the W3C to describe the syntax of XML.

The only deviation from EBNF is the use of comments to identify additional constraints that are impossible or cumbersome to communicate in EBNF. In the **Declarations** section, comments are used 4 times to indicate that a name is only valid if it is the name of a previously defined constant. The only other usage of comments is in the definition of `statement`, to indicate that `allocateStatement`'s are invalid when nested within a function call.

The `root` symbol represents an individual document, including those linked or included through the requisite declarations.

```
root = declaration*
```

## Declarations

```
declaration = compilerDeclaration
    | constantDeclaration
    | ( "public" | "private" ) nearObject
    | ( "extern" | "intern" ) farObject

compilerDeclaration = "include" (string | name /*constant string*/)
    | "link" (string | name /*constant string*/)

constantDeclaration = "constant" name "=" (number | string | name /*constant*/)

nearObject = arrayHeader
    | functionHeader statement

farObject = arrayHeader
    | functionHeader

arrayHeader = name "[" (number | name /*constant number*/)+ "]"

functionHeader = "(" name name* (name "...")? [ ";" name+ ] ")"
```

## Statements

```
statement = returnStatement
    | letStatement
    | allocateStatement /*allocateStatement not allowed if nested within a functionCall*/
    | ifStatement
    | whileStatement
    | blockStatement
    | expression
    
returnStatement = "return" expression
    
letStatement = "let" name "=" expression
    | name ":=" expression

allocateStatement = "allocate" name "[" expression "]"

ifStatement = "if" expression statement ("else" statement)?

whileStatement = "while" expression statement

blockStatement = "{" (statement)* "}"
```

## Expressions

```
expression = blockStatement
    | functionCall
    | name
    | number
    | string

functionCall = "(" name (expression)* ")"

name = [a-zA-Z_][a-zA-Z0-9_]*

number = [0-9]+
    | "0x" [0-9a-fA-F]+
    | "0b" [01]+
    | "'" (ANY | BACKSLASH ANY) "'"

string = '"' (ANY - '"' | BACKSLASH ANY)* '"'

BACKSLASH = '\'
ANY = [^]
```
