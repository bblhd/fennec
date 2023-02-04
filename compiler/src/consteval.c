#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include <cache.h>
#include <tokeniser.h>

typedef long const_t;

struct NamedConstant {
	struct NamedConstant *next;
	char *name;
	const_t value;
} *namedConstants = NULL;

const_t consteval_expression();

const_t consteval_name();
const_t consteval_number();
const_t consteval_builtin();

int declaration_constant() {
	if (tokens_keyword("constant")) {
		char *name = stringCache_give(tokens_name());
		struct NamedConstant *c;
		for (c = namedConstants; c && c->name != name; c = c->next);
		tokens_assert(c == NULL, "redefinition of constant");
		
		c = malloc(sizeof(struct NamedConstant));
		c->next = namedConstants;
		c->name = name;
		c->value = 1;
		
		if (tokens_symbol("=")) {
			c->value = consteval_expression();
		}
		namedConstants = c;
		return 1;
	}
	return 0;
}

int consteval_isConstant(char *name) {
	struct NamedConstant *c;
	for (c = namedConstants; c && c->name != name; c = c->next);
	return c != NULL;
}

const_t consteval_getConstant(char *name) {
	struct NamedConstant *c;
	for (c = namedConstants; c && c->name != name; c = c->next);
	tokens_assert(c!=NULL, "nonexistant constant");
	return c->value;
}

const_t consteval_expression() {
	if (tokens_symbol("(")) {
		int n = 0;
		const_t base;
		if (tokens_keyword("add")) {
			while (!tokens_symbol(")")) {
				tokens_assert(!tokens_eof(), "no end to constant builtin");
				if (n++) base += consteval_expression();
				else base = consteval_expression();
			}
		} else if (tokens_keyword("sub")) {
			while (!tokens_symbol(")")) {
				tokens_assert(!tokens_eof(), "no end to constant builtin");
				if (n++) base -= consteval_expression();
				else base = consteval_expression();
			}
		} else if (tokens_keyword("mul")) {
			while (!tokens_symbol(")")) {
				tokens_assert(!tokens_eof(), "no end to constant builtin");
				if (n++) base *= consteval_expression();
				else base = consteval_expression();
			}
		} else if (tokens_keyword("div")) {
			base = 0;
			while (!tokens_symbol(")")) {
				tokens_assert(!tokens_eof(), "no end to constant builtin");
				if (n++) base /= consteval_expression();
				else base = consteval_expression();
			}
		} else {
			tokens_error("nonexistant constant builtin");
		}
		return base;
		
	} else if (tokens_name_check()) {
		char *name = stringCache_give(tokens_name());
		return consteval_getConstant(name);
		
	} else if (tokens_number_check()) {
		return (const_t) tokens_number();
		
	}
	tokens_error("invalid or malformed constant expression");
	return 0;
}
