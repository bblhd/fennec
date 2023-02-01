#ifndef FENNEC_ARRANGER_H
#define FENNEC_ARRANGER_H

#include <intermediary.h>

void arranger_setup(void (*assertFunction)(int, char *));
void arranger_switch(struct IntermediaryProgram *new);

void arranger_stringLiteral(char *s);
void arranger_numericLiteral(long i);

void arranger_if();
void arranger_unless();
void arranger_else();
void arranger_fi();
void arranger_while();
void arranger_do();
void arranger_done();

void arranger_variable(int id);
void arranger_let(int id);
void arranger_allocate(int id);

void arranger_startcall();
void arranger_pass();
void arranger_endcall();

#endif
