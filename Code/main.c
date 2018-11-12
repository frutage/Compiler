#include "stdio.h"
#include "syntax.tab.h"
extern FILE* yyin;
extern int yylineno;
//extern int yydebug;
int yylex();
int yyrestart(FILE* f);
int yyparse();
void printTree();

int  main(int argc, char** argv) {
  if (argc <= 1) 
    return 1;
  FILE* f = fopen(argv[1], "r");
  if (!f) {
    perror(argv[1]);
    return 1;
  }
  yylineno = 1;
  yyrestart(f);
//  yydebug = 1;
  yyparse();
  printTree();
  return 0;
}

