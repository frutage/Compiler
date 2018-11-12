%option yylineno
%{
  #include "syntax.tab.h"
  #include<stdio.h> 
  int yycolumn = 1;
  int lexErrors = 0;
  int decodeOctalOrHex(char*);
  #define YY_USER_ACTION \
    yylloc.first_line = yylloc.last_line = yylineno; \
    yylloc.first_column = yycolumn; \
    yylloc.last_column = yycolumn + yyleng - 1; \
    yycolumn += yyleng;
%}

DIGITS 0|[1-9][0-9*]
OCT 0[0-7]+
HEX 0[xX][0-9A-Fa-f]+
INT 0|[1-9][0-9]*|0[0-7]+|0[xX][0-9A-Fa-f]+
BASE (([0-9]+\.[0-9]*)|(\.[0-9]+))
FLOAT (([0-9]+\.[0-9]*)|(\.[0-9]+))([eE][-+]?[0-9]+)?
ILLEGALHEX 0[xX][0-9A-Fa-f]*([G-Zg-z]+[0-9A-Fa-f]*)+
ILLEGALOCT (0[0-7]+([89a-fA-F]+[0-7]*)+)|(0[89a-fA-F][0-9A-Fa-f]*)
ILLEGALFLOAT [eE][-+][0-9]+|([0-9]*\.([0-9]*\.)+[0-9]*)[eE][-+]?[0-9]*\.([0-9]*\.)*[0-9]*|(([0-9]+\.[0-9]*)|(\.[0-9]+))[eE]|\.[eE][-+]?[0-9]+|([0-9]*\.([0-9]*\.)+[0-9]*)([eE][-+]?[0-9]+)?|(([0-9]+\.[0-9]*)|(\.[0-9]+))[eE][-+]?[0-9]*\.([0-9]*\.)*[0-9]*|[0-9]+[eE][-+]?[0-9]*
ID [a-zA-Z_][0-9a-zA-Z_]{0,31}
ILLEGALID 0[0-9a-fA-F]*([g-zG-Z_]+[0-9a-fA-F]*)+|[1-9][0-9]*([a-zA-Z_]+[0-9]*)+
SPACE " "*

%%

{INT} { /* printf("INT ");*/ 
        yylval.type_int = decodeOctalOrHex(yytext);
        return INT; 
      }
{FLOAT} { /* printf("FLOAT ");*/ 
          yylval.type_float = atof(yytext);
          return FLOAT; 
        }
{ILLEGALHEX} {
               yylval.type_int = 0;
               lexErrors += 1;
               printf("Error type A at line %d: Illegal hexadecimal number \"%s\"\n", yylineno, yytext);
               return INT;
              }
{ILLEGALOCT} {
               yylval.type_int = 0;
               lexErrors += 1;
               printf("Error type A at line %d: Illegal octal number \"%s\"\n", yylineno, yytext);
               return INT;
              }
{ILLEGALFLOAT} {
                 yylval.type_float = 0.0;
                 lexErrors += 1;
                 printf("Error type A at line %d: Illegal float number \"%s\"\n", yylineno, yytext);
                 return FLOAT;  
               }
{ILLEGALID} {
              yylval.type_string = "\0";
              lexErrors += 1;
              printf("Error type A at line %d: Illegal identifier \"%s\"\n", yylineno, yytext);
              return ID;
            }
{SPACE} {}
\t {}
"//" { char c = input();
       while (c != '\n') c = input(); 
     }
"/*" { char c1 = input();
       char c2 = input();
       while ((!( c1 == '*' && c2 == '/')) && (c2 != EOF)) {
         c1 = c2;
         c2 = input();
       }
       if(c2 == EOF) {
          lexErrors += 1;
          printf("Error type B at line %d: unexpected $end\n", yylineno);
       }
    }
";" { return SEMI; }
"," { return COMMA; }
>|<|>=|<=|==|!= { return RELOP; }
"=" { return ASSIGNOP; }
"+" { return PLUS; }
"-" { return MINUS; }
"*" { return STAR; }
"/" { return DIV; }
"&&" { return AND; }
"||" { return OR; }
"." { return DOT; }
"!" { return NOT; }
"(" { return LP; }
")" { return RP; }
"[" { return LB; }
"]" { return RB; }
"{" { return LC; }
"}" { return RC; }
\r\n|\n { yycolumn = 1; }
struct { return STRUCT; }
return { return RETURN; }
if { return IF; }
else { return ELSE; }
while { return WHILE; }
int|float { /* printf("TYPE ");*/ 
            yylval.type_string = strdup(yytext);
            return TYPE; 
          }
{ID} { /* printf("ID ");*/ 
       yylval.type_string = strdup(yytext);
       return ID; 
     }
. { lexErrors += 1; 
    printf("Error type A at line %d: Mysterious character \'%s\'\n", yylineno, yytext);
  }
 
%%

/* Convert string to int */
int decodeOctalOrHex(char* text) {
  if(text[0] == '0' && text[1] != '\0') {
    int len = strlen(text)-1;
    int val = 0;
    if(text[1] == 'x' || text[1] == 'X') {
      // decode hex digit
      for (int i = 2; i <= len; i++) {
        if (text[i] >= '0' && text[i] <= '9')
          val = val * 16 + (text[i] - '0');
        else if (text[i] >= 'a' && text[i] <= 'f')
          val = val * 16 + (text[i] - 'a' + 10);
        else
          val = val * 16 + (text[i] - 'A' + 10);
      }
      return val;

    } else {
      //decode octal digit
      for (int i = 1; i <= len; i++)
        val = val * 8 + (text[i] - '0');
      return val;

    }
  } else {
    return atoi(text);
  }
}
