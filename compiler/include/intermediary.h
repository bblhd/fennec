#ifndef FENNEC_INTERMEDIARY_H
#define FENNEC_INTERMEDIARY_H

#include <stdint.h>

//note: operations between two arguments use the saved register and the return register, in that order (ebx/rbx, and eax/rax on x86)

// pseudo-structures:
	// PASSING, PASS, PASS, ..., PASS, CALL
	// SAVE, [ADD, SUB, ...]
	// IF, ELSE, FI
	// WHILE, DO, END

enum IntermediaryAction {
	IACT_FUNCTION, //function argument
	IACT_NUMBER, //number argument
	IACT_STRING, //string argument
	IACT_ARRAY, //array argument
	
	//count argument
	
	IACT_PASSING,
	IACT_VARIABLES,
	
	//variable/variable-like argument
	
	IACT_VARIABLE,
	IACT_LET,
	IACT_ALLOCATE,
	IACT_PASS,
	
	//no arguments
	
	IACT_IF,
	IACT_UNLESS,
	IACT_ELSE,
	IACT_END,
	
	IACT_WHILE,
	IACT_DO,
	IACT_DONE,
	
	IACT_CALL, //a = a(...)
	IACT_SAVE, //b = a
	
	IACT_ADD, //a = b + a
	IACT_SUB, //a = b - a
	IACT_NEG, //a = 0 - a
	IACT_MUL, //a = b * a
	IACT_DIV, //a = b / a
	IACT_IDIV, //a = b / a (signed)
	IACT_MOD, //a = b % a (% as in proper modulo)
	
	IACT_EQ, //a = b == a
	IACT_NE, //a = b != a
	IACT_LT, //a = b < a
	IACT_LTE, //a = b <= a
	IACT_GT, //a = b > a
	IACT_GTE, //a = b >= a
	
	IACT_AND, //a = b && a
	IACT_OR, //a = b || a
	IACT_NOT, //a = !a
	
	IACT_BAND, //a = b & a
	IACT_BOR, //a = b | a
	IACT_BNOT, //a = ~a
	IACT_LSL, //a = b << a
	IACT_LSR, //a = b >> a (unsigned)
	IACT_ASL, //a = b << a
	IACT_ASR, //a = b >> a (signed)
	
	IACT_LOAD1, //a = byte [b]
	IACT_STORE1, //byte [b] = a
	IACT_LOAD2, //a = 2byte [b]
	IACT_STORE2, //2byte [b] = a
	IACT_LOAD4, //a = 4byte [b]
	IACT_STORE4, //4byte [b] = a
	IACT_LOAD8, //a = 8byte [b]
	IACT_STORE8, //8byte [b] = a
	IACT_LOADWORD, //a = {WORD_SIZE}byte [b]
	IACT_STOREWORD, //{WORD_SIZE}byte [b] = a
	
	IACT_FINAL
};

struct IntermediaryInstruction {
	enum IntermediaryAction action;
	union {
		char *function;
		char *array;
		char *string;
		long number;
		int count;
		int variable;
	};
};

struct IntermediaryProgram {
	struct IntermediaryInstruction *instruction;
	size_t length;
	size_t max;
};

void intermediary_setup(struct IntermediaryProgram *program);
void intermediary_cleanup(struct IntermediaryProgram *program);
void intermediary_print(struct IntermediaryProgram *program);

#endif
