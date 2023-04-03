#ifndef FENNEC_PROGRAM_H
#define FENNEC_PROGRAM_H

#include <stddef.h>

typedef long const_t;


enum ProgramType {
	//call
	PT_CALL,
	
	//bytes, words
	PT_DECLARE,
	
	//variable
	PT_GET_LOCAL,
	PT_ADDRESS_LOCAL,
	
	//duad
	PT_SEQUENCE,
	PT_WHILE,
	
	//triad
	PT_IF,
	PT_UNLESS,
	
	//string
	PT_STRING,
	PT_GET_GLOBAL,
	PT_ADDRESS_GLOBAL,
	PT_ADDRESS_FUNCTION,
	
	//number
	PT_NUMBER,
};

typedef struct Program program_t;

struct Program {
	enum ProgramType type;
	union {
		struct {
			program_t *cond, *then, *elses;
		};
		struct {
			program_t *a, *b;
		};
		program_t *inner;
		struct {
			char *function;
			int arglen;
			program_t *args[];
		};
		struct {
			int bytes, words;
		};
		char *name;
		int var;
		char *string;
		long long value;
	};
};

struct ProgramCall {
	enum ProgramType type;
	char *name;
	int length;
	program_t *values[];
};

struct ProgramMonad {
	enum ProgramType type;
	program_t *a;
};

struct ProgramDuad {
	enum ProgramType type;
	program_t *a, *b;
};

struct ProgramTriad {
	enum ProgramType type;
	program_t *a, *b, *c;
};

struct ProgramVariable {
	enum ProgramType type;
	int variable;
};

struct ProgramDeclare {
	enum ProgramType type;
	int bytes, words;
};

struct ProgramString {
	enum ProgramType type;
	char *string;
};

struct ProgramNumber {
	enum ProgramType type;
	long long value;
};

program_t *program_if(program_t *cond, program_t *then, program_t *elses);
program_t *program_unless(program_t *cond, program_t *then, program_t *elses);
program_t *program_while(program_t *pre, program_t *post);
program_t *program_call(char *name, size_t n, program_t **var);
program_t *program_byted(unsigned int size, program_t *next);
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

#endif
