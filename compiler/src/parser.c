#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdbool.h>
#include <stdarg.h>

#include <cache.h>
#include <tokeniser.h>
#include <arranger.h>
#include <consteval.h>

#define any(f...) varg_or(f, NULL)
int varg_or(int (*f)(void), ...);

int statement_root();
int declaration_root();

int varg_or(int (*f)(void), ...) {
	int r = 0;
	va_list args;
	va_start(args, f);
	while (f) {
		r = f();
		if (r) break;
		f = va_arg(args, int (*)(void));
	}
	va_end(args);
	return r;
}

int expression_root();

int declaration_root() {
	bool isPublic = 0;
	if (tokens_keyword("public")) {
		isPublic = 1;
	} else {
		tokens_assert(tokens_keyword("private"), "missing visibility qualifier (public or private)");
	}
	(void) isPublic;
	declaration_constant();
	expression_root();
	return 1;
}

int code_block();
int statement_if();
int statement_while();
int statement_let();
int statement_express();

int statement_root() {
	return any(code_block, statement_if, statement_while, statement_let, statement_express);
}

int code_block() {
	if (tokens_symbol("{")) {
		while (!tokens_symbol("}")) {
			tokens_assert(!tokens_eof(), "no end of block");
			tokens_assert(statement_root(), "malformed statement");
		}
		return 1;
	}
	return 0;
}

int statement_if() {
	if (tokens_keyword("if")) {
		tokens_assert(expression_root(), "malformed or missing expression");
		arranger_if();
	} else if (tokens_keyword("unless")) {
		tokens_assert(expression_root(), "malformed or missing expression");
		arranger_unless();
	} else return 0;
	
	tokens_assert(statement_root(), "malformed or missing statement");
	if (tokens_keyword("else")) {
		arranger_else();
		tokens_assert(statement_root(), "malformed or missing statement");
	}
	arranger_end();
	return 1;
}

int statement_while() {
	if (tokens_keyword("while")) {
		arranger_while();
		tokens_assert(expression_root(), "malformed or missing expression");
		arranger_do();
		tokens_assert(statement_root(), "malformed or missing statement");
		arranger_done();
		return 1;
	}
	return 0;
}

int statement_let() {
	if (tokens_keyword("let")) {
		char *name = stringCache_give(tokens_name());
		tokens_assert(tokens_symbol("="), "missing equals sign in let statement");
		tokens_assert(expression_root(), "malformed or missing expression");
		(void) name;
		//todo
		arranger_let(0); //todo
		return 1;
	}
	return 0;
}

int statement_express() {
	if (tokens_keyword("express")) {
		tokens_assert(expression_root(), "malformed or missing expression");
		return 1;
	}
	return 0;
}

int expression_string();
int expression_name();
int expression_number();
int expression_call();

int expression_root() {
	return any(code_block, expression_call, expression_string, expression_name, expression_number);
}

int expression_call() {
	if (tokens_symbol("(")) {
		if (tokens_keyword("const")) {
			tokens_assert(!tokens_eof(), "missing closing bracket in const builtin");
			arranger_number(consteval_expression());
			tokens_assert(tokens_symbol(")"), "more than 1 expression given for const builtin");
		} else if (tokens_keyword("add")) {
			tokens_assert(!tokens_eof(), "missing closing bracket in add builtin");
			tokens_assert(expression_root(), "malformed or missing expression in add builtin");
			while (!tokens_symbol(")")) {
				arranger_save();
				tokens_assert(!tokens_eof(), "missing closing bracket in add builtin");
				tokens_assert(expression_root(), "malformed or missing expression in add builtin");
				arranger_add();
			}
		} else if (tokens_keyword("sub")) {
			tokens_assert(!tokens_eof(), "missing closing bracket in sub builtin");
			tokens_assert(expression_root(), "malformed or missing expression in sub builtin");
			while (!tokens_symbol(")")) {
				arranger_save();
				tokens_assert(!tokens_eof(), "missing closing bracket in sub builtin");
				tokens_assert(expression_root(), "malformed or missing expression in sub builtin");
				arranger_sub();
			}
		} else {
			char *name = stringCache_give(tokens_name());
			(void) name;
			arranger_reserve();
			while (!tokens_symbol(")")) {
				tokens_assert(!tokens_eof(), "missing closing bracket in function call");
				tokens_assert(expression_root(), "malformed or missing expression in function call");
				arranger_pass();
			}
			arranger_call(name);
		}
		return 1;
	}
	return 0;
}

int expression_string() {
	if (tokens_string_check()) {
		arranger_string(stringCache_give(tokens_string()));
		return 1;
	}
	return 0;
}

int expression_name() {
	if (tokens_name_check()) {
		char *name = stringCache_give(tokens_name());
		if (consteval_isConstant(name)) {
			arranger_number(consteval_getConstant(name));
		} else {
			//todo
			arranger_variable(0);
		}
		return 1;
	}
	return 0;
}

int expression_number() {
	if (tokens_number_check()) {
		arranger_number(tokens_number());
		return 1;
	}
	return 0;
}

