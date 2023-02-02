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

#define MAX_stack_DEPTH 16
struct {
	int stack[MAX_CALL_DEPTH];
	int depth;
	int most;
} jumps;

void (*arranger_assert)(int, char *);

void arranger_setup(void (*assertFunction)(int, char *)) {
	arranger_assert = assertFunction;
	calls.depth = 0;
}

void arranger_if() {
	printf("if\n");
}

void arranger_unless() {
	printf("unless\n");
}

void arranger_else() {
	printf("else\n");
}

void arranger_end() {
	printf("end");
}

void arranger_while() {
	printf("while\n");
}

void arranger_do() {
	printf("do\n");
}

void arranger_done() {
	printf("done\n");
}

void arranger_variable(int id) {
	printf("load from v%i\n", id);
}

void arranger_let(int id) {
	printf("store in v%i\n", id);
}

void arranger_string(char *s) {
	printf("string \"%s\"\n", s);
}

void arranger_number(long n) {
	printf("number (%lu)\n", n);
}

void arranger_reserve() {
	arranger_assert(calls.depth < MAX_CALL_DEPTH, "function call max depth exceeded (ARRANGER)");
	printf("reserve\n");
	calls.depth++;
}

void arranger_pass() {
	arranger_assert(calls.depth > 0, "trailing pass to function call (ARRANGER)");
	printf("pass to v%i\n", calls.size[calls.depth-1]);
	calls.size[calls.depth-1]++;
}

void arranger_call(char *name) {
	arranger_assert(calls.depth > 0, "function call not properly began (ARRANGER)");
	calls.depth--;
	printf("call %s\n", name);
}


