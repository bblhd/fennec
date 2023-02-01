#ifndef FENNEC_ARRANGER_H
#define FENNEC_ARRANGER_H

void arranger_setup(void (*assertFunction)(int, char *));

void arranger_string(char *s);
void arranger_number(long i);
void arranger_array(char *name);

void arranger_variable(int id);
void arranger_let(int id);
void arranger_allocate(int size);

void arranger_if();
void arranger_unless();
void arranger_else();
void arranger_end();

void arranger_while();
void arranger_do();
void arranger_done();

void arranger_reserve();
void arranger_pass();
void arranger_call(char *name);

void arranger_save();
	
void arranger_add();
void arranger_sub();
void arranger_neg();

#endif
