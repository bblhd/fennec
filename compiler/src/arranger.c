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

#define MAX_JUMP_DEPTH 16
struct {
	int stack[MAX_JUMP_DEPTH];
	int depth;
	int most;
} jumps;

void (*arranger_assert)(int, char *);

void arranger_setup(void (*assertFunction)(int, char *)) {
	arranger_assert = assertFunction;
	calls.depth = 0;
	jumps.depth = 0;
	jumps.most = 0;
}

int jumps_push() {
	arranger_assert(jumps.depth < MAX_JUMP_DEPTH, "maximum control flow depth exceeded (ARRANGER)");
	return (jumps.stack[jumps.depth++] = jumps.most++);
}

int jumps_pull() {
	arranger_assert(jumps.depth > 0, "trailing control flow ending clause (ARRANGER)");
	return jumps.stack[--jumps.depth];
}

void arranger_if() {
	printf("if zero, goto %i\n", jumps_push());
}

void arranger_unless() {
	printf("if non-zero, goto %i\n", jumps_push());
}

void arranger_else() {
	int j = jumps_pull();
	printf("goto %i\n", jumps_push());
	printf("label %i\n", j);
}

void arranger_end() {
	printf("label %i\n", jumps_pull());
}

void arranger_while() {
	printf("label %i\n", jumps_push());
}

void arranger_do() {
	printf("if zero, goto %i\n", jumps_push());
}

void arranger_done() {
	int j = jumps_pull();
	printf("goto %i\n", jumps_pull());
	printf("label %i\n", j);
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
	calls.size[calls.depth-1] = 0;
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

void arranger_save() {
	printf("save\n");
}

void arranger_add() {
	printf("save\n");
}

void arranger_sub() {
	printf("sub\n");
}

void arranger_neg() {
	printf("neg\n");
}


