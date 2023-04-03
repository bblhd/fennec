#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "cache.h"
#include "tokeniser.h"

typedef long const_t;

const_t consteval() {
	if (tokens_symbol("(")) {
		int n = 0;
		const_t base;
		if (tokens_keyword("add")) {
			while (!tokens_symbol(")")) {
				tokens_assert(!tokens_eof(), "no end to constant builtin");
				if (n++) base += consteval();
				else base = consteval();
			}
		} else if (tokens_keyword("sub")) {
			while (!tokens_symbol(")")) {
				tokens_assert(!tokens_eof(), "no end to constant builtin");
				if (n++) base -= consteval();
				else base = consteval();
			}
		} else if (tokens_keyword("mul")) {
			while (!tokens_symbol(")")) {
				tokens_assert(!tokens_eof(), "no end to constant builtin");
				if (n++) base *= consteval();
				else base = consteval();
			}
		} else if (tokens_keyword("div")) {
			base = 0;
			while (!tokens_symbol(")")) {
				tokens_assert(!tokens_eof(), "no end to constant builtin");
				if (n++) base /= consteval();
				else base = consteval();
			}
		} else {
			tokens_error("nonexistant constant builtin");
		}
		return base;
		
	} else if (tokens_name_check()) {
		char *name = tokens_name();
		cache_t *c = cache_get(name);
		free(name);
		tokens_assert(c->is.constant, "undefined constant");
		return c->constant;
		
	} else if (tokens_number_check()) {
		return (const_t) tokens_number();
	}
	
	tokens_error("invalid or malformed constant expression");
	return 0;
}
