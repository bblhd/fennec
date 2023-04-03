void tokens_error(char *msg);
void tokens_assert(int cond, char *msg);

int tokens_open(char *path);
void tokens_close();

int tokens_eof();
int tokens_symbol(char *symbol);
int tokens_keyword(char *keyword);
char *tokens_string();
char *tokens_name();
long tokens_number();
int tokens_string_check();
int tokens_name_check();
int tokens_number_check();
