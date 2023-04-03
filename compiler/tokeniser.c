#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdbool.h>

#define MAXLAYERS 8
struct {
	char *path;
	unsigned int line;
	char *buffer;
	unsigned int length;
	unsigned int cursor;
} data[MAXLAYERS];
int top = -1;

void tokens_error(char *msg) {
	fprintf(stderr, "Fennec compiler error at line %u in file %s: %s\n", data[top].line, data[top].path, msg);
	exit(EXIT_FAILURE);
}

void tokens_assert(int cond, char *msg) {
	if (!cond) tokens_error(msg);
}

int tokens_open(char *path) {
	tokens_assert(top+1 < MAXLAYERS, "Files nested too deeply!");
	
	top++;
	data[top].path = malloc(strlen(path) + 1);
	if (data[top].path) {
		strcpy(data[top].path, path);
		FILE *file = fopen(data[top].path, "rb");
		fseek(file, 0, SEEK_END);
		data[top].length = ftell(file);
		if (data[top].length > 0) {
			rewind(file);
			data[top].buffer = malloc(data[top].length + 1);
			if (data[top].buffer) {
				fread(data[top].buffer, data[top].length, 1, file);
				fclose(file);
				data[top].buffer[data[top].length] = 0;
				
				data[top].line = 1;
				data[top].cursor = 0;
				return data[top].length;
			}
		}
		fclose(file);
		free(data[top].path);
	}
	top--;
	return 0;
}

void tokens_close() {
	if (data[top].path) free(data[top].path);
	if (data[top].buffer) free(data[top].buffer);
	top--;
}

int tokens_eof() {
	return top < 0 || data[top].cursor >= data[top].length;
}

char tokens_offset(int offset) {
	return top >= 0 && data[top].cursor + offset < data[top].length ? data[top].buffer[data[top].cursor + offset] : 0;
}

void tokens_advance(int offset) {
	data[top].cursor += offset;
}

void tokens_junk() {
	if (tokens_eof()) return;
	while (1) {
		if (isspace(tokens_offset(0))) {
			do {
				if (tokens_offset(0) == '\n') data[top].line++;
				data[top].cursor++;
			} while (isspace(tokens_offset(0)));
		} else if (tokens_offset(0) == '#') {
			while (tokens_offset(0) && tokens_offset(0) != '#') {
				data[top].cursor++;
			}
		} else break;
	}
}

int tokens_exact(char *str) {
	int i = 0;
	while (str[i] != 0 && tokens_offset(i) == str[i]) i++;
	return str[i] == 0 ? i : 0;
}

int tokens_symbol(char *symbol) {
	tokens_junk();
	int matched = tokens_exact(symbol);
	if (matched) {
		tokens_advance(matched);
		return 1;
	}
	return 0;
}

int tokens_keyword(char *keyword) {
	tokens_junk();
	int matched = tokens_exact(keyword);
	if (matched && !isalnum(tokens_offset(matched)) && tokens_offset(matched) != '_') {
		tokens_advance(matched);
		return 1;
	}
	return 0;
}

int tokens_string_check() {
	tokens_junk();
	return tokens_offset(0) == '"';
}

char *tokens_string() {
	//todo: add escape characters to string
	tokens_junk();
	if (tokens_offset(0) == '"') {
		int length = 1;
		while (tokens_offset(length) && tokens_offset(length) != '"') length++;
		tokens_assert(tokens_offset(length), "No end to string!");
		char *str = malloc(length);
		memcpy(str, data[top].buffer+data[top].cursor+1, length-1);
		str[length-1] = 0;
		tokens_advance(length+1);
		return str;
	}
	return NULL;
}

int tokens_name_check() {
	tokens_junk();
	if (tokens_eof()) return 0;
	return isalpha(tokens_offset(0));
}

char *tokens_name() {
	tokens_junk();
	if (isalpha(tokens_offset(0))) {
		int length = 1;
		while (isalnum(tokens_offset(length)) || tokens_offset(length) == '_') length++;
		char *name = malloc(length+1);
		memcpy(name, data[top].buffer+data[top].cursor, length);
		name[length] = 0;
		tokens_advance(length);
		return name;
	}
	return NULL;
}

int isbase(char digit, int base) {
	return (digit >= '0' && digit < '0'+base)
		|| (digit >= 'A' && digit < 'A'+base-10)
		|| (digit >= 'a' && digit < 'a'+base-10);
}

int digval(char digit) {
	return digit >= '0' && digit <= '9' ? digit-'0'
		: digit >= 'A' && digit <= 'Z' ? digit-'A'+10
		: digit >= 'a' && digit <= 'z' ? digit-'a'+10
		: 0;
}

int tokens_number_check() {
	tokens_junk();
	return tokens_offset(0) == '\'' || tokens_offset(0) == '-' || isdigit(tokens_offset(0));
}

long tokens_number_positive();

long tokens_number() {
	tokens_junk();
	if (tokens_eof()) return 0;
	//todo: add escape characters to char
	if (tokens_offset(0) == '\'' && tokens_offset(2) == '\'') {
		return tokens_offset(1);
	} else if (tokens_offset(0) == '-' && isdigit(tokens_offset(1))) {
		tokens_advance(1);
		return -tokens_number_positive();
	} else if (isdigit(tokens_offset(0))) {
		return tokens_number_positive();
	}
	return 0;
}

long tokens_number_positive() {
	int base = 10;
	if (tokens_exact("0b")) {
		base = 2;
		tokens_advance(2);
	} else if (tokens_exact("0x")) {
		base = 16;
		tokens_advance(2);
	}
	
	long value = 0;
	while (isbase(tokens_offset(0), base)) {
		value *= base;
		value += digval(data[top].buffer[data[top].cursor]);
		tokens_advance(1);
	}
	
	return value;
}

