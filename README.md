# Fennec
Experimental assembly-compiled programming language. Currently a work in progress.

Goals for this project:
- [x] compiling to x86 and x86_64
- [ ] compiling to arm32 and arm64
- [ ] bootstrapping compiler (fennec compiler written in fennec)
- [ ] utilising simple optimisations (storing values in registers, inlining functions, etc)

## Usage

While in the project folder, compile and link a fennec program for a given platform (operating system + ISA) using:

```
<platform>/build.sh <filename>.fen
```

Output file will be an executable and will end up in `./bin`. Available platforms are `linux_x86_32`, `linux_x86_64`, and `macos_x86_64`.

The build scripts assume that the computer running the build script is on the same platform as it, so they probably wont work if used on the wrong machine. `compiler.lua` does not assume this, so feel free to construct new build scripts if you want to try to cross-compile.

Currently only compiles to x86 assembly and type checking is currently unimplemented. I would recommend against use in serious projects, as of yet.

Good luck!

### Requirements

- lua (5.4)
- nasm
