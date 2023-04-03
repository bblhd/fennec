#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdbool.h>
#include <stdarg.h>

#include <dirent.h>

#include "program.h"
#include "cache.h"

typedef long const_t;

void basicError(char *msg);
void basicAssert(int cond, char *msg);

#define INCLUDE_PATHS_MAX 32
int includePathsTop = 0;
char *includePaths[INCLUDE_PATHS_MAX];

void addIncludePath(char *path) {
	basicAssert(includePathsTop < INCLUDE_PATHS_MAX, "reached maximum number of include paths");
	includePaths[includePathsTop++] = path;
}

char *searchIncludePaths(char *name) {
	
	for (int i = 0; i < includePathsTop; i++) {
		DIR *dir = opendir(includePaths[i]);
		struct dirent *ent;
		if (dir == NULL) continue;
		while ((ent = readdir(dir))) {
			if (strcmp(name, ent->d_name)==0) {
				return includePaths[i];
			}
		}
		closedir(dir);
	}
	return NULL;
}

cache_t *cache = NULL;

cache_t *cache_get(char *s) {
	if (s==NULL) return NULL;
	
	cache_t **where = &cache;
	
	while (*where != NULL && strcmp(s, (*where)->name) > 0) {
		where = &((*where)->next);
	}
	if (*where != NULL && strcmp(s, (*where)->name) == 0) {
		return *where;
	}
	
	cache_t *new = malloc(sizeof(cache_t) + strlen(s) + 1);
	if (new == NULL) {return NULL;}
	
	new->is.include = false;
	new->is.constant = false;
	new->is.function = false;
	new->is.array = false;
	new->is.variable = false;
	new->is.string = false;
	
	new->next = *where;
	strcpy(new->name, s);
	*where = new;
	return new;
}

cache_t *cache_give(char *s) {
	cache_t *c = cache_get(s);
	free(s);
	return c;
}

void cache_free() {
	struct Cache *c = cache, *nc = NULL;
	while (c != NULL) {
		nc = c->next;
		free(c);
		c = nc;
	}
}
