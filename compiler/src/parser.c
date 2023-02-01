#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdbool.h>
#include <stdarg.h>

#include <tokeniser.h>
#include <arranger.h>
#include <intermediary.h>

struct StringCache {
	struct StringCache *next;
	char string[];
} *stringCache = NULL;

char *stringCache_store(char *s) {
	struct StringCache **where = &stringCache;
	
	while (*where != NULL && strcmp(s, (*where)->string) > 0) {
		where = &((*where)->next);
	}
	if (*where != NULL && strcmp(s, (*where)->string) == 0) {
		return (*where)->string;
	}
	
	struct StringCache *new = malloc(sizeof(struct StringCache) + strlen(s) + 1);
	if (new == NULL) {return NULL;}
	
	new->next = *where;
	strcpy(new->string, s);
	*where = new;
	return new->string;
}

char *stringCache_give(char *old) {
	char *new = stringCache_store(old);
	free(old);
	return new;
}

void stringCache_free() {
	struct StringCache *sc = stringCache, *nsc = NULL;
	while (sc != NULL) {
		nsc = sc->next;
		free(sc);
		sc = nsc;
	}
}

int statement_root();

int main(int argc, char **argv) {
	(void) argc;
	(void) argv;
	
	if (argc > 1) {
		arranger_setup(tokens_assert);
		
		tokens_open(argv[1]);
		
		struct IntermediaryProgram testprogram;
		intermediary_setup(&testprogram);
		arranger_switch(&testprogram);
		
		statement_root();
		
		intermediary_print(&testprogram);
		intermediary_cleanup(&testprogram);
		
		tokens_close();
		
		stringCache_free();
	}
	return 0;
}

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

//int declaration_root() {
	//bool isPublic = 0;
	//if (tokens_keyword("public")) {
		//isPublic = 1;
	//} else {
		//tokens_asset(tokens_keyword("private"), "missing visibility qualifier (public or private)");
	//}
//}

//int declaration_function() {
	//return varg_or(statement_if, expression_root);
//}

//int declaration_constant() {
	//return varg_or(statement_if, expression_root);
//}

int code_block();
int statement_if();
int statement_let();
int expression_root();

int statement_root() {
	return varg_or(code_block, statement_if, statement_let, expression_root);
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
	arranger_fi();
	return 1;
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

int expression_string();
int expression_name();
int expression_number();

int expression_root() {
	return varg_or(code_block, expression_string, expression_name, expression_number);
}

int expression_string() {
	if (tokens_string_check()) {
		arranger_stringLiteral(stringCache_give(tokens_string()));
		return 1;
	}
	return 0;
}

int expression_name() {
	if (tokens_name_check()) {
		char *name = stringCache_give(tokens_name());
		(void) name;
		//todo
		arranger_variable(0);
		return 1;
	}
	return 0;
}

int expression_number() {
	if (tokens_number_check()) {
		arranger_numericLiteral(tokens_number());
		return 1;
	}
	return 0;
}

