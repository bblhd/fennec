#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <varargs.h>

#include "program.h"

program_t *program_iforunless(enum ProgramType this, enum ProgramType other, program_t *cond, program_t *then, program_t *elses) {
	if (cond == NULL) return NULL;
	else if (then == NULL && elses == NULL) return cond;
	else {
		program_t *p = malloc(sizeof(struct ProgramTriad));
		p->type = this;
		p->cond = cond;
		p->then = then;
		p->elses = elses;
		
		if (then == NULL) {
			p->type = other;
			p->then = elses;
			p->elses = then;
		}
		return p;
	}
	return NULL;
}

program_t *program_if(program_t *cond, program_t *then, program_t *elses) {
	return program_iforunless(PT_IF, PT_UNLESS, cond, then, elses);
}

program_t *program_unless(program_t *cond, program_t *then, program_t *elses) {
	return program_iforunless(PT_UNLESS, PT_IF, cond, then, elses);
}

program_t *program_while(program_t *pre, program_t *post) {
	program_t *p = malloc(sizeof(struct ProgramDuad));
	p->type = PT_WHILE;
	p->pre = pre;
	p->post = post;
}

program_t *program_call(char *name, int n, program_t **values) {
	program_t *p = malloc(sizeof(struct ProgramCall) + n * sizeof(program_t *));
	p->type = PT_CALL;
	p->function = name;
	p->arglen = n;
	for (int i = 0; i < n; i++) {
		p->args[i] = values[i];
	}
}

program_t *program_declare(int bytes, int words, program_t *next) {
	program_t *p = malloc(sizeof(struct ProgramDeclare));
}

program_t *program_setLocal(unsigned int var, program_t *val);
program_t *program_getLocal(unsigned int var);
program_t *program_addressLocal(unsigned int var);
program_t *program_declare(program_t *next);
program_t *program_setGlobal(char *name, program_t *val);
program_t *program_getGlobal(char *name);
program_t *program_addressGlobal(char *name);
program_t *program_addressFunction(char *name);
program_t *program_string(char *string);
program_t *program_number(long long number);