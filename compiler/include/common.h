#ifndef FENNEC_COMMON_H
#define FENNEC_COMMON_H

#define any(f...) varg_or(f, NULL)
int varg_or(int (*f)(void), ...);

char *stringCache_store(char *s);
char *stringCache_give(char *old);

#endif
