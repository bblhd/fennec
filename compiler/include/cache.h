#ifndef FENNEC_CACHE_H
#define FENNEC_CACHE_H

char *stringCache_store(char *s);
char *stringCache_give(char *old);
void stringCache_free();

void addIncludePath(char *path);
char *searchIncludePaths(char *name);

#endif
