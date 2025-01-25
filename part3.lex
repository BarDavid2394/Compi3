%{
// Declarations
#include <stdio.h>
#include <string.h>
#include "part3_helpers.hpp"
#include "part3.tab.hpp"

void print_str();

%}
%option yylineno noyywrap


digit       [0-9]
letter      [a-zA-Z]
id          {letter}({letter}|{digit}|_)*
keywords    (int|float|void|write|read|va_arg|while|do|if|then|else|return)
symbols     [(){},:;,]
integernum  {digit}+
realnum     {integernum}(\.{integernum})?([eE][+-]?{integernum})?
whitespace  [\t\n\r ]+
dquote      \"
str         {dquote}((\\.|[^"\r\n])*([^"\\\r\n])*)*{dquote}

relop       "=="|"<>"|"<"|"<="|">"|">="
addop       "+"|"-"
mulop       "*"|"/"
assign      "="
and         "&&"
or          "||"
not         "!"
comment     "#"[^\n]*

%%

{keywords} {
                    if(strcmp( yytext ,"int") == 0)
                        return tk_int;
                    if(strcmp(yytext , "float") == 0)
                        return tk_float;
                    if(strcmp(yytext , "void") == 0)
                        return tk_void;
                    if(strcmp(yytext , "write") == 0)
                        return tk_write;
                    if(strcmp(yytext , "read") == 0)
                        return tk_read;
                    if(strcmp(yytext , "va_arg") == 0)
                        return tk_va_arg;
                    if(strcmp(yytext , "while") == 0)
                        return tk_while;
                    if(strcmp(yytext , "do") == 0)
                        return tk_do;
                    if(strcmp(yytext , "if") == 0)
                        return tk_if;
                    if(strcmp(yytext , "then") == 0)
                        return tk_then;
                    if(strcmp(yytext , "else") == 0)
                        return tk_else;
                    if(strcmp(yytext , "return") == 0)
                        return tk_return;                       
}
{symbols}  {
                    yylval.name = yytext;
                    return yytext[0];
}

{integernum}  {
                    yylval.name = yytext;
                    return tk_int_num;
}
{realnum}     {
                    yylval.name = yytext; 
                    return tk_real_num;
}
{id}       {
                    yylval.name = yytext; 
                    return tk_id;
}         
{relop}    {
                    yylval.name = yytext; 
                    return tk_relop;
}         
{addop}    {
                    yylval.name = yytext;
                    return tk_addop; 
}         
{mulop}    {
                    yylval.name = yytext; 
                    return tk_mulop;
}         
{assign}   {
                    yylval.name = yytext;
                    return tk_assign;
}         
{and}      {
                    yylval.name = yytext;
                    return tk_and;
}         
{or}       {
                    yylval.name = yytext;
                    return tk_or;
}         
{not}      {
                    yylval.name = yytext; 
                    return tk_not;
}         
{str}       {   
                    char* string = yytext;
                    string++;
                    string[yyleng - 2] = '\0';
                    yylval.name = string;
                    return tk_str;
} 
"..."		 {
					yylval.name = "...";
					return tk_ellipsis;
}       
{comment}           ;  // Ignore comments
{whitespace}        ;  // Ignore whitespaces
.         {
                    printf("Lexical error: '%s' in line number %d\n", yytext, yylineno);
                    exit(LEXICAL_ERROR);
}

%%

void return_str() {
    char* str = yytext;
    str++;
    str[yyleng - 2] = '\0';
    printf("<str,%s>", str);
}



