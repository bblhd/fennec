#ifndef FENNEC_CACHE_H
#define FENNEC_CACHE_H

#include <stdbool.h>
#include "program.h"

struct Cache {
	struct Cache *next;
	struct {
		bool include,constant,function,array,variable,string;
	} is;
	struct {
		program_t *program;
		int requiredArgs;
		bool moreAllowed;
	} function;
	const_t constant;
	char *include;
	size_t array;
	char name[];
};

typedef struct Cache cache_t;

cache_t *cache_get(char *s);
cache_t *cache_give(char *s);
void cache_free();

void addIncludePath(char *path);
char *searchIncludePaths(char *name);

#endif
