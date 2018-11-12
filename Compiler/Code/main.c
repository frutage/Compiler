#include <stdio.h>
#include "syntax.tab.h"
#include "semantic.h"
void print_type(Type type);

extern FILE* yyin;
extern int yylineno;
//extern int yydebug;
extern TreeNode* head;
extern int syntaxErrors, lexErrors;
int yylex();
int yyrestart(FILE* f);
int yyparse();
void printTree();
void semanticParser(TreeNode* head);

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
//yydebug = 1;
  yyparse();
//  printTree();
  if (syntaxErrors == 0 && lexErrors == 0)
    semanticParser(head);
  return 0;
}
