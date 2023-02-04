#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdbool.h>
#include <stdarg.h>

#include <cache.h>
#include <tokeniser.h>
#include <arranger.h>
#include <consteval.h>

char *infile = NULL;
char *outfile = NULL;

enum {DONT_COMPILE, ONLY_COMPILE, COMPILE_AND_LINK} compileGoahead = DONT_COMPILE;

void cmdline(char **args, int n);

int main(int argc, char **argv) {
	cmdline(argv, argc);
	
	if (compileGoahead) {
		if (outfile == NULL) outfile = "a.out";
		printf("%s to %s from %s\n", compileGoahead==ONLY_COMPILE ? "compiling" : "building", outfile, infile);
		
		//stringCache_free();
	}
	return 0;
}

void basicError(char *msg) {
	fprintf(stderr, "Fennec compiler error: %s\n", msg);
	exit(EXIT_FAILURE);
}

void basicAssert(int cond, char *msg) {
	if (!cond) basicError(msg);
}

void versionMessage() {
	printf("fennec compiler v1 (dev)\n");
}

void helpMessage(char *command) {
	versionMessage();
	printf("Usage:\n");
	printf("\t%s (help | version)\n", command);
	printf("\t%s (build | compile) [-i path | -l alias | -o file]... [--] infile [outfile]\n", command);
	printf("Actions:\n");
	printf("\thelp      Prints this help message.\n");
	printf("\tversion   Prints the current version information.\n");
	printf("\tbuild     Compiles and then links all files referenced by the root file.\n");
	printf("\tcompile   Skips the linking stage and doesn't compile included files, only the root file.\n");
	printf("Options:\n");
	printf("\t-i path   Adds a directory to be searched for module sources.\n");
	printf("\t-l alias  Defines a direct module file alias of the form \"name=/path/to/file\".\n");
	printf("\t-o file   Adds a precompiled file to be linked when linking.\n");
}

void cmdline(char **args, int n) {
	if (n >= 1) {
		char *command = args[0];
		args++; n--;
		
		if (n < 1 || strcmp(args[0], "help") == 0) {
			helpMessage(command);
		} else if (strcmp(args[0], "version") == 0) {
			versionMessage();
		} else {
			if (strcmp(args[0], "compile") == 0) {
				compileGoahead = ONLY_COMPILE;
			} else if (strcmp(args[0], "build") == 0) {
				compileGoahead = COMPILE_AND_LINK;
			} else {
				basicError("invalid action given.");
			}
			args++; n--;
			
			enum {OPTIONS, INFILE, OUTFILE, FINISHED} argStage = OPTIONS;
			while (n > 0 && argStage != FINISHED) {
				if (argStage == OPTIONS) {
					if (strcmp(args[0], "-i")==0 && n > 1) {
						addIncludePath(args[1]);
						args+=2; n-=2;
					} else if (strcmp(args[0], "-l")==0 && n > 1) {
						printf("library %s\n", args[1]);
						args+=2; n-=2;
					} else if (strcmp(args[0], "-o")==0 && n > 1) {
						printf("object %s\n", args[1]);
						args+=2; n-=2;
					} else if (strcmp(args[0], "--")==0) {
						argStage = INFILE;
						args++; n--;
					} else {
						argStage = INFILE;
					}
				} else if (argStage == INFILE) {
					infile = args[0];
					args++; n--;
					argStage = OUTFILE;
				} else if (argStage == OUTFILE) {
					outfile = args[0];
					args++; n--;
					argStage = FINISHED;
				}
			}
			basicAssert(argStage == OUTFILE || argStage == FINISHED, "infile must be provided.");
			basicAssert(argStage != FINISHED || n==0, "trailing command line arguments.");
		}
	}
}
