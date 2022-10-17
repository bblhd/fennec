# fennec
Minimalist compiled programming language (WIP).

Goals for this project:
- bootstrapping compiler (fennec compiler written in fennec).
- compiling to x86, x86-64, arm32, and aarch64
- simple optimisations only (storing values in registers, inlining functions, etc)

## Usage

Run WIP compiler using `lua fennec.lua <filename>`

Currently only compiles to x86 32-bit assembly, many features are
unimplemented, such as type checking and an equivalent to C header files.

Also is currently untested and probably completely broken, so please don't actually use it yet.

Also there is no documentation either.
