#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "tokeniser.h"
#include "cache.h"
#include "program.h"

int declaration_root();
int statement_root();
int expression_root();

bool importing = false;

void parser_top() {
	while (declaration_root());
}

const_t consteval();

int declaration_root() {
	int public = tokens_keyword("public");
	if (!public) tokens_keyword("private");
	
	if (tokens_keyword("module")) {
		cache_t *c = cache_give(tokens_string());
		tokens_assert(c!=NULL, "missing module name");
		tokens_assert(c->is.include, "undefined module name");
		
		if (importing && !public) {
			(void) NULL;
		} else {
			if (c->is.include) {
				tokens_open(c->include);
				if (!importing) {
					importing = true;
					parser_top();
					importing = false;
				}
				tokens_close();
			}
		}
		return 1;
	} else if (tokens_keyword("constant")) {
		cache_t *c = cache_give(tokens_name());
		tokens_assert(!c->is.constant, "redefinition of constant");
		
		if (importing && !public) {
			if (tokens_symbol("=")) {
				(void) consteval();
			}
		} else {
			c->constant = 1;
			if (tokens_symbol("=")) {
				c->constant = consteval();
			}
			c->is.constant = true;
			printf("constant %s = %li\n", c->name, c->constant);
		}
		
		return 1;
	} else {
		int external = tokens_keyword("external");
		(void) external;
		
		if (tokens_keyword("variable")) {
		} else if (tokens_keyword("array")) {
		} else if (tokens_keyword("function")) {
		}
	}
	return 0;
}
