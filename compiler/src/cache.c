#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdbool.h>
#include <stdarg.h>

#include <dirent.h>

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

struct StringCache {
	struct StringCache *next;
	char string[];
} *stringCache = NULL;

char *stringCache_store(char *s) {
	struct StringCache **where = &stringCache;
	
	while (*where != NULL && strcmp(s, (*where)->string) > 0) {
		where = &((*where)->next);
	}
	if (*where != NULL && strcmp(s, (*where)->string) == 0) {
		return (*where)->string;
	}
	
	struct StringCache *new = malloc(sizeof(struct StringCache) + strlen(s) + 1);
	if (new == NULL) {return NULL;}
	
	new->next = *where;
	strcpy(new->string, s);
	*where = new;
	return new->string;
}

char *stringCache_give(char *old) {
	char *new = stringCache_store(old);
	free(old);
	return new;
}

void stringCache_free() {
	struct StringCache *sc = stringCache, *nsc = NULL;
	while (sc != NULL) {
		nsc = sc->next;
		free(sc);
		sc = nsc;
	}
}
