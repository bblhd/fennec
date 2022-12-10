# fennec
Minimalist compiled programming language. Currently a work in progress.

Goals for this project:
- bootstrapping compiler (fennec compiler written in fennec)
- compiling to both 32 bit and 64 bit x86 and arm architectures
- utilising simple optimisations (storing values in registers, inlining functions, etc)

## Usage

While in the project folder, compile and link a fennec program using `<platform>/compile.sh <filename>.fen`.
Output file will be an executable.
For example, to compile `test.fen` for 64 bit x86 Linux, use `linux_x86_64/compile.sh test.fen`

Platforms available currently are `linux_x86_32`, `linux_x86_64`, and `macos_x86_64`. More will be added in future.

Currently only compiles to limited platforms with limited capability, many features are
unimplemented, such as type checking and an equivalent to C header files.

I would recommend against use in serious projects, as of yet.

Also there is no documentation either.

Good luck!
