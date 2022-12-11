# fennec
Experimental assembly-compiled programming language. Currently a work in progress.

Goals for this project:
- bootstrapping compiler (fennec compiler written in fennec)
- compiling to both 32 bit and 64 bit x86 and arm architectures
- utilising simple optimisations (storing values in registers, inlining functions, etc)

## Usage

While in the project folder, compile and link a fennec program using `<platform>/build.sh <filename>.fen`.
Output file will be an executable and will end up in `./bin`.
For example, to compile `test.fen` for 64 bit x86 Linux, use `./linux_x86_64/build.sh test.fen`, you can then run the program using `./bin/test`.

While it may seem as though they support cross compiling, the build scripts currently just use the resident `ld` command, which will attempt to link for your system. This is an issue that will be fixed in the future.

Available platforms are `linux_x86_32`, `linux_x86_64`, and `macos_x86_64`. More will be added in future.

Currently only compiles to x86 and isn't properly cross-platform, even on supported platforms.
Type checking is currently unimplemented and some syntax isn't finalised, especially arrays and memory allocation.

I would recommend against use in serious projects, as of yet.

Also there is no documentation either.

Good luck!
