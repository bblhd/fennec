name:=fennec

compile:
	gcc main.c -no-pie -o $(name)  -Wall -Wextra -Werror -Wno-trigraphs

install: $(outfile)
	mv $(name) /usr/local/bin
