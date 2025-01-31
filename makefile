# Makefile for part3
all: rx-cc

rx-cc: lex.yy.o part3.tab.o part3_helpers.o
	g++ -std=c++11 -o $@ $^

part3_helpers.o: part3_helpers.cpp part3_helpers.hpp
	g++ -std=c++11 -c -o $@ part3_helpers.cpp

part3.tab.o: part3.tab.cpp part3.tab.hpp
	g++ -std=c++11 -c -o $@ part3.tab.cpp

lex.yy.o: lex.yy.c part3.tab.hpp
	g++ -std=c++11 -c -o $@ lex.yy.c

lex.yy.c: part3.lex part3.tab.hpp part3_helpers.hpp
	flex part3.lex

part3.tab.cpp part3.tab.hpp: part3.ypp part3_helpers.hpp
	bison -d part3.ypp

.PHONY: clean
clean:
	rm -f rx-cc *.o *.tab.* lex.yy.c