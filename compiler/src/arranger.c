#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdbool.h>

#include <intermediary.h>

#define MAX_CALL_DEPTH 16
struct {
	int position[MAX_CALL_DEPTH];
	int size[MAX_CALL_DEPTH];
	int depth;
} calls;

void (*arranger_assert)(int, char *);

struct IntermediaryProgram *current;

void intermediary_setup(struct IntermediaryProgram *program) {
	program->instruction = NULL;
	program->max = 0;
	program->length = 0;
}

void intermediary_cleanup(struct IntermediaryProgram *program) {
	if (program->instruction) free(program->instruction);
	program->max = 0;
	program->length = 0;
}

void intermediary_grow(struct IntermediaryProgram *program, size_t amount) {
	program->length = amount;
	if (program->max < program->length) {
		if (program->max == 0) program->max = 1;
		while (program->max < program->length) {
			program->max *= 2;
		}
		program->instruction = realloc(program->instruction, sizeof(struct IntermediaryInstruction) * program->max);
	}
}

void intermediary_add(struct IntermediaryProgram *program, struct IntermediaryInstruction instruction) {
	intermediary_grow(program, program->length + 1);
	program->instruction[program->length - 1] = instruction;
}

struct {
	char description[27];
	enum {IVAL_NONE, IVAL_FUNCTION, IVAL_ARRAY, IVAL_STRING, IVAL_NUMBER, IVAL_COUNT, IVAL_VARIABLE} datatype;
} instructionPrintDetails[IACT_FINAL] = {
	{"get function", IVAL_FUNCTION},
	{"number", IVAL_NUMBER},
	{"string", IVAL_STRING},
	{"get array", IVAL_ARRAY},
	
	{"passing", IVAL_COUNT},
	{"variables", IVAL_COUNT},
	
	{"get from", IVAL_VARIABLE},
	{"put in", IVAL_VARIABLE},
	{"allocate to", IVAL_VARIABLE},
	{"pass to", IVAL_VARIABLE},
	
	{"if so, then", IVAL_NONE},
	{"if not, then", IVAL_NONE},
	{"else", IVAL_NONE},
	{"end", IVAL_NONE},
	
	{"while", IVAL_NONE},
	{"do", IVAL_NONE},
	{"done", IVAL_NONE},
	
	{"call", IVAL_NONE},
	{"save", IVAL_NONE},
	
	{"add", IVAL_NONE},
	{"sub", IVAL_NONE},
	{"neg", IVAL_NONE},
	{"mul", IVAL_NONE},
	{"div", IVAL_NONE},
	{"idiv", IVAL_NONE},
	{"mod", IVAL_NONE},
	
	{"eq", IVAL_NONE},
	{"ne", IVAL_NONE},
	{"lt", IVAL_NONE},
	{"lte", IVAL_NONE},
	{"gt", IVAL_NONE},
	{"gte", IVAL_NONE},
	
	{"and", IVAL_NONE},
	{"or", IVAL_NONE},
	{"not", IVAL_NONE},
	
	{"band", IVAL_NONE},
	{"bor", IVAL_NONE},
	{"bnot", IVAL_NONE},
	{"lsl", IVAL_NONE},
	{"lsr", IVAL_NONE},
	{"asl", IVAL_NONE},
	{"asr", IVAL_NONE},
	
	{"load 1 byte", IVAL_NONE},
	{"store 1 byte", IVAL_NONE},
	{"load 2 bytes", IVAL_NONE},
	{"store 2 bytes", IVAL_NONE},
	{"load 4 bytes", IVAL_NONE},
	{"store 4 bytes", IVAL_NONE},
	{"load 8 bytes", IVAL_NONE},
	{"store 8 bytes", IVAL_NONE},
	{"load word", IVAL_NONE},
	{"store word", IVAL_NONE},
};

void intermediary_print_partialFallback(struct IntermediaryInstruction inst) {
	printf("%s", instructionPrintDetails[inst.action].description);
	switch (instructionPrintDetails[inst.action].datatype) {
		case IVAL_NONE:
		break;
		
		case IVAL_FUNCTION:
		case IVAL_ARRAY:
		printf(" %s", inst.string);
		break;
		case IVAL_STRING:
		printf(" \"%s\"", inst.string);
		break;
		
		case IVAL_NUMBER:
		printf(" %li", inst.number);
		break;
		case IVAL_COUNT:
		printf("[%u]", inst.count);
		break;
		case IVAL_VARIABLE:
		printf(" v%u", inst.variable);
		break;
	}
	printf("\n");
}

void intermediary_print(struct IntermediaryProgram *program) {
	for (unsigned int i = 0; i < program->length; i++) {
		intermediary_print_partialFallback(program->instruction[i]);
	}
}

void arranger_setup(void (*assertFunction)(int, char *)) {
	arranger_assert = assertFunction;
	calls.depth = 0;
}

void arranger_switch(struct IntermediaryProgram *new) {
	current = new;
}

int arranger_add_uncasted(struct IntermediaryInstruction instruction) {
	int i = current->length;
	intermediary_add(current, instruction);
	return i;
}

#define arranger_add(act, data...) arranger_add_uncasted((struct IntermediaryInstruction) {.action=act, data})

void arranger_if() {
	arranger_add(IACT_IF);
}

void arranger_unless() {
	arranger_add(IACT_UNLESS);
}

void arranger_else() {
	arranger_add(IACT_ELSE);
}

void arranger_fi() {
	arranger_add(IACT_END);
}

void arranger_while() {
	arranger_add(IACT_WHILE);
}

void arranger_do() {
	arranger_add(IACT_DO);
}

void arranger_done() {
	arranger_add(IACT_DONE);
}

void arranger_variable(int id) {
	arranger_add(IACT_VARIABLE, .variable=id);
}

void arranger_let(int id) {
	arranger_add(IACT_LET, .variable=id);
}

void arranger_allocate(int id) {
	arranger_add(IACT_ALLOCATE, .variable=id);
}

void arranger_stringLiteral(char *s) {
	arranger_add(IACT_STRING, .string=s);
}

void arranger_numericLiteral(long n) {
	arranger_add(IACT_NUMBER, .number=n);
}

void arranger_startcall() {
	arranger_assert(calls.depth < MAX_CALL_DEPTH, "function call max depth exceeded (ARRANGER)");
	calls.depth++;
	calls.position[calls.depth-1] = arranger_add(IACT_PASSING, .count=0);
}

void arranger_pass() {
	arranger_assert(calls.depth > 0, "trailing pass to function call (ARRANGER)");
	arranger_add(IACT_PASS, .variable=calls.size[calls.depth-1]);
	calls.size[calls.depth-1]++;
}

void arranger_endcall() {
	arranger_assert(calls.depth > 0, "function call not properly began (ARRANGER)");
	current->instruction[calls.position[calls.depth-1]].count = calls.size[calls.depth-1];
	calls.depth--;
	arranger_add(IACT_CALL);
}
