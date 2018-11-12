%{
  #include "lex.yy.c"
  #include "syntree.h"

  TreeNode* head;
  int syntaxErrors = 0;
  void yyerror(char *msg);
%}

%union {
  struct TreeNode* node;
  int type_int;
  float type_float;
  char* type_string;
}

/* declared tokens */
%token <type_string> TYPE STRUCT LC RC LB RB LP RP DIV ASSIGNOP PLUS MINUS AND OR STAR NOT DOT SEMI COMMA
%token <type_string> ID IF WHILE ELSE RETURN RELOP
%token <type_int> INT
%token <type_float> FLOAT

%right ASSIGNOP
%left OR
%left AND
%left RELOP
%left MINUS PLUS
%left STAR DIV
%right NOT UMINUS
%left DOT LB RB LP RP

/* declared non-terminal symbols */
%type <node> Program ExtDefList ExtDef ExtDecList Specifier FunDec VarDec CompSt StructSpecifier OptTag Tag Exp DefList Def Stmt Args ParamDec StmtList VarList Dec DecList

%%

/* High-level definitions */

Program : ExtDefList {
  $$ = createNode("Program", 1, @$.first_line);
  $$->firstChild = $1;
  head = $$;
  }
  ;

ExtDefList : ExtDef ExtDefList { 
  $$ = createNode("ExtDefList", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = $2; }
  |
  { $$ = createNode("ExtDefList", 1, @$.first_line); }
  ;

ExtDef : Specifier ExtDecList SEMI {
  TreeNode* n3 = createNode("SEMI", 0, @3.first_line);
  $$ = createNode("ExtDef", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = $2;
  $2->nextSibling = n3; }
  | Specifier ExtDecList error {
  TreeNode* n3 = createNode("error", 0, @3.first_line);
  $$ = createNode("ExtDef", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = $2;
  $2->nextSibling = n3; }
  | Specifier SEMI { 
  TreeNode* n2 = createNode("SEMI", 0, @2.first_line);
  $$ = createNode("ExtDef", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2; }
  | Specifier FunDec CompSt {
  $$ = createNode("ExtDef", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = $2;
  $2->nextSibling = $3; }
  | error SEMI {
  TreeNode* n1 = createNode("error", 0, @1.first_line);
  TreeNode* n2 = createNode("SEMI", 0, @2.first_line);
  $$ = createNode("ExtDef", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = n2; }
  | Specifier error {
  TreeNode* n2 = createNode("error", 0, @2.first_line);
  $$ = createNode("ExtDef", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2; }
  ;

ExtDecList : VarDec  { 
  $$ = createNode("ExtDecList", 1, @$.first_line);
  $$->firstChild = $1; }
  | VarDec COMMA ExtDecList { 
  TreeNode* n2 = createNode("COMMA", 0, @2.first_line);
  $$ = createNode("ExtDecList", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = $3; }
  | error COMMA ExtDecList {
  TreeNode* n1 = createNode("error", 0, @1.first_line);
  TreeNode* n2 = createNode("COMMA", 0, @2.first_line);
  $$ = createNode("ExtDecList", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = n2;
  n2->nextSibling = $3; }
;

/* Specifiers */

Specifier : TYPE  {
  TreeNode* n1 = createNode("TYPE", 0, @1.first_line);
  n1->exp.str = $1;
  $$ = createNode("Specifier", 1, @$.first_line);
  $$->firstChild = n1; }
  | StructSpecifier { 
  $$ = createNode("Specifier", 1, @$.first_line);
  $$->firstChild = $1; }
  ;

StructSpecifier : STRUCT OptTag LC DefList RC { 
  TreeNode* n1 = createNode("STRUCT", 0, @1.first_line);
  TreeNode* n3 = createNode("LC", 0, @3.first_line);
  TreeNode* n5 = createNode("RC", 0, @5.first_line);
  $$ = createNode("StructSpecifier", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = $2;
  $2->nextSibling = n3;
  n3->nextSibling = $4;
  $4->nextSibling = n5; }
  | STRUCT OptTag LC error RC {
  TreeNode* n1 = createNode("STRUCT", 0, @1.first_line);
  TreeNode* n3 = createNode("LC", 0, @3.first_line);
  TreeNode* n4 = createNode("error", 0, @4.first_line);
  TreeNode* n5 = createNode("RC", 0, @5.first_line);
  $$ = createNode("StructSpecifier", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = $2;
  $2->nextSibling = n3;
  n3->nextSibling = n4;
  n4->nextSibling = n5; }
  | STRUCT error LC DefList RC {
  TreeNode* n1 = createNode("STRUCT", 0, @1.first_line);
  TreeNode* n3 = createNode("LC", 0, @3.first_line);
  TreeNode* n2 = createNode("error", 0, @2.first_line);
  TreeNode* n5 = createNode("RC", 0, @5.first_line);
  $$ = createNode("StructSpecifier", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = n2;
  n2->nextSibling = n3;
  n3->nextSibling = $4;
  $4->nextSibling = n5; }
  | STRUCT Tag {
  TreeNode* n1 = createNode("STRUCT", 0, @1.first_line);
  $$ = createNode("StructSpecifier", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = $2; }
  | STRUCT error {
  TreeNode* n1 = createNode("STRUCT", 0, @1.first_line);
  TreeNode* n2 = createNode("error", 0, @1.first_line);
  $$ = createNode("StructSpecifier", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = n2; }
  ;

OptTag : 
  { $$ = createNode("OptTag", 1, @$.first_line); }
  | ID { 
  TreeNode* n1 = createNode("ID", 0, @1.first_line);
  n1->exp.str = $1;
  $$ = createNode("OptTag", 1, @$.first_line);
  $$->firstChild = n1; }
  ;

Tag : ID { 
  TreeNode* n1 = createNode("ID", 0, @1.first_line);
  n1->exp.str = $1;
  $$ = createNode("Tag", 1, @$.first_line);
  $$->firstChild = n1; }
  ;

/* Declaratiors */

VarDec : ID { 
  TreeNode* n1 = createNode("ID", 0, @1.first_line);
  n1->exp.str = $1;
  $$ = createNode("VarDec", 1, @$.first_line);
  $$->firstChild = n1; }
  | VarDec LB INT RB {
  TreeNode* n2 = createNode("LB", 0, @2.first_line);
  TreeNode* n3 = createNode("INT", 0, @3.first_line);
  n3->exp.intVal = $3;
  TreeNode* n4 = createNode("RB", 0, @4.first_line);
  $$ = createNode("VarDec", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = n3;
  n3->nextSibling = n4; }
  | VarDec LB error RB {
  TreeNode* n2 = createNode("LB", 0, @2.first_line);
  TreeNode* n3 = createNode("error", 0, @3.first_line);
  TreeNode* n4 = createNode("RB", 0, @4.first_line);
  $$ = createNode("VarDec", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = n3;
  n3->nextSibling = n4; }
  ;

FunDec : ID LP VarList RP {
  TreeNode* n1 = createNode("ID", 0, @1.first_line);
  n1->exp.str = $1;
  TreeNode* n2 = createNode("LP", 0, @2.first_line);
  TreeNode* n4 = createNode("RP", 0, @4.first_line);
  $$ = createNode("FunDec", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = n2;
  n2->nextSibling = $3;
  $3->nextSibling = n4; }
  | ID LP RP {
  TreeNode* n1 = createNode("ID", 0, @1.first_line);
  n1->exp.str = $1;
  TreeNode* n2 = createNode("LP", 0, @2.first_line);
  TreeNode* n3 = createNode("RP", 0, @3.first_line);
  $$ = createNode("FunDec", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = n2;
  n2->nextSibling = n3; }
  ;

VarList : ParamDec COMMA VarList {
  TreeNode* n2 = createNode("COMMA", 0, @2.first_line);
  $$ = createNode("VarList", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = $3; }
  | ParamDec {
  $$ = createNode("VarList", 1, @$.first_line);
  $$->firstChild = $1; }
  ;

ParamDec : Specifier VarDec {
  $$ = createNode("ParamDec", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = $2; }
  ;

/* Statements */
CompSt : LC DefList StmtList RC {
  TreeNode* n1 = createNode("LC", 0, @1.first_line);
  TreeNode* n4 = createNode("RC", 0, @4.first_line);
  $$ = createNode("CompSt", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = $2;
  $2->nextSibling = $3;
  $3->nextSibling = n4; }
  ;

StmtList : Stmt StmtList {
  $$ = createNode("StmtList", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = $2; }
  |
  { $$ = createNode("StmtList", 1, @$.first_line); }  
  ;

Stmt : error SEMI {
  TreeNode* n1 = createNode("error", 0, @1.first_line);
  TreeNode* n2 = createNode("SEMI", 0, @2.first_line);
  $$ = createNode("Stmt", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = n2;
  }
  | Exp SEMI {
  TreeNode* n2 = createNode("SEMI", 0, @2.first_line);
  $$ = createNode("Stmt", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2; }
  | Exp error {
  // missing SEMI
  TreeNode* n2 = createNode("error", 0, @2.first_line);
  $$ = createNode("Stmt", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  }
  | CompSt {
  $$ = createNode("Stmt", 1, @$.first_line);
  $$->firstChild = $1; }
  | RETURN Exp SEMI {
  TreeNode* n1 = createNode("RETURN", 0, @1.first_line);
  TreeNode* n3 = createNode("SEMI", 0, @3.first_line);
  $$ = createNode("Stmt", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = $2;
  $2->nextSibling = n3; }
  | IF LP Exp RP Stmt {
  TreeNode* n1 = createNode("IF", 0, @1.first_line);
  TreeNode* n2 = createNode("LP", 0, @2.first_line);
  TreeNode* n4 = createNode("RP", 0, @4.first_line);
  $$ = createNode("Stmt", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = n2;
  n2->nextSibling = $3;
  $3->nextSibling = n4;
  n4->nextSibling = $5; }
  | IF LP Exp RP Stmt ELSE Stmt {
  TreeNode* n1 = createNode("IF", 0, @1.first_line);
  TreeNode* n2 = createNode("LP", 0, @2.first_line);
  TreeNode* n4 = createNode("RP", 0, @4.first_line);
  TreeNode* n6 = createNode("ELSE", 0, @6.first_line);
  $$ = createNode("Stmt", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = n2;
  n2->nextSibling = $3;
  $3->nextSibling = n4;
  n4->nextSibling = $5;
  $5->nextSibling = n6;
  n6->nextSibling = $7; }
  | WHILE LP Exp RP Stmt {
  TreeNode* n1 = createNode("WHILE", 0, @1.first_line);
  TreeNode* n2 = createNode("LP", 0, @2.first_line);
  TreeNode* n4 = createNode("RP", 0, @4.first_line);
  $$ = createNode("Stmt", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = n2;
  n2->nextSibling = $3;
  $3->nextSibling = n4;
  n4->nextSibling = $5; }
  | WHILE LP error RP Stmt {
  TreeNode* n1 = createNode("WHILE", 0, @1.first_line);
  TreeNode* n2 = createNode("LP", 0, @2.first_line);
  TreeNode* n3 = createNode("error", 0, @3.first_line);
  TreeNode* n4 = createNode("RP", 0, @4.first_line);
  $$ = createNode("Stmt", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = n2;
  n2->nextSibling = n3;
  n3->nextSibling = n4;
  n4->nextSibling = $5; }
  ;

/* Local Definitions */

DefList : Def DefList {
  $$ = createNode("DefList", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = $2; }
  |
  { $$ = createNode("DefList", 1, @$.first_line); }
  ;
Def : Specifier DecList SEMI {
  TreeNode* n3 = createNode("SEMI", 0, @3.first_line);
  $$ = createNode("Def", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = $2;
  $2->nextSibling = n3; }
  | Specifier DecList error {
  TreeNode* n3 = createNode("error", 0, @3.first_line);
  $$ = createNode("Def", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = $2;
  $2->nextSibling = n3; }
  ;

DecList : Dec {
  $$ = createNode("DecList", 1, @$.first_line);
  $$->firstChild = $1; }
  | Dec COMMA DecList {
  TreeNode* n2 = createNode("COMMA", 0, @2.first_line);
  $$ = createNode("DecList", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = $3; }
  ;

Dec : VarDec {
  $$ = createNode("Dec", 1, @$.first_line);
  $$->firstChild = $1; }
  | VarDec ASSIGNOP Exp {
  TreeNode* n2 = createNode("ASSIGNOP", 0, @2.first_line);
  $$ = createNode("Dec", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = $3; }
  ;

/* Expressions */

Exp : error {
  TreeNode* n1 = createNode("error", 0, @1.first_line);
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = n1;
  }
  | Exp ASSIGNOP Exp {
  TreeNode* n2 = createNode("ASSIGNOP", 0, @2.first_line);
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = $3; }
  | Exp AND Exp {
  TreeNode* n2 = createNode("AND", 0, @2.first_line);
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = $3; }
  | Exp OR Exp {
  TreeNode* n2 = createNode("OR", 0, @2.first_line);
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = $3; }
  | Exp RELOP Exp {
  TreeNode* n2 = createNode("RELOP", 0, @2.first_line);
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = $3; }
  | Exp PLUS Exp {
  TreeNode* n2 = createNode("PLUS", 0, @2.first_line);
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = $3; }
  | Exp MINUS Exp {
  TreeNode* n2 = createNode("MINUS", 0, @2.first_line);
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = $3; }
  | Exp STAR Exp {
  TreeNode* n2 = createNode("STAR", 0, @2.first_line);
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = $3; }
  | Exp DIV Exp {
  TreeNode* n2 = createNode("DIV", 0, @2.first_line);
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = $3; }
  | LP Exp RP {
  TreeNode* n1 = createNode("LP", 0, @1.first_line);
  TreeNode* n3 = createNode("RP", 0, @3.first_line);
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = $2;
  $2->nextSibling = n3; }
  | MINUS Exp %prec UMINUS {
  TreeNode* n1 = createNode("MINUS", 0, @1.first_line);
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = $2; }
  | NOT Exp {
  TreeNode* n1 = createNode("NOT", 0, @1.first_line);
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = $2; }
  | ID LP Args RP {
  TreeNode* n1 = createNode("ID", 0, @1.first_line);
  n1->exp.str = $1;
  TreeNode* n2 = createNode("LP", 0, @2.first_line);
  TreeNode* n4 = createNode("RP", 0, @4.first_line);
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = n2;
  n2->nextSibling = $3;
  $3->nextSibling = n4; }
  | ID LP error RP { 
  TreeNode* n1 = createNode("ID", 0, @1.first_line);
  n1->exp.str = $1;
  TreeNode* n2 = createNode("LP", 0, @2.first_line);
  TreeNode* n3 = createNode("error", 0, @2.first_line);
  TreeNode* n4 = createNode("RP", 0, @4.first_line);
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = n2;
  n2->nextSibling = n3;
  n3->nextSibling = n4; }
  | ID LP RP {
  TreeNode* n1 = createNode("ID", 0, @1.first_line);
  n1->exp.str = $1;
  TreeNode* n2 = createNode("LP", 0, @2.first_line);
  TreeNode* n3 = createNode("RP", 0, @3.first_line);
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = n1;
  n1->nextSibling = n2;
  n2->nextSibling = n3; }
  | Exp LB Exp RB {
  TreeNode* n2 = createNode("LB", 0, @2.first_line);
  TreeNode* n4 = createNode("RB", 0, @4.first_line);
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = $3;
  $3->nextSibling = n4; }
  | Exp LB error RB {
  TreeNode* n2 = createNode("LB", 0, @2.first_line);
  TreeNode* n3 = createNode("error", 0, @3.first_line);
  TreeNode* n4 = createNode("RB", 0, @4.first_line);
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = n3;
  n3->nextSibling = n4; }
  
  | Exp DOT ID {
  TreeNode* n2 = createNode("DOT", 0, @2.first_line);
  TreeNode* n3 = createNode("ID", 0, @3.first_line);
  n3->exp.str = $3;
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = n3; }
  | ID {
  TreeNode* n1 = createNode("ID", 0, @1.first_line);
  n1->exp.str = $1;
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = n1; }
  | INT {
  TreeNode* n1 = createNode("INT", 0, @1.first_line);
  n1->exp.intVal = $1;
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = n1; }
  | FLOAT {
  TreeNode* n1 = createNode("FLOAT", 0, @1.first_line);
  n1->exp.floatVal = $1;
  $$ = createNode("Exp", 1, @$.first_line);
  $$->firstChild = n1; }
  ;
Args : Exp COMMA Args {
  TreeNode* n2 = createNode("COMMA", 0, @2.first_line);
  $$ = createNode("Args", 1, @$.first_line);
  $$->firstChild = $1;
  $1->nextSibling = n2;
  n2->nextSibling = $3; }
  | Exp {
  $$ = createNode("Args", 1, @$.first_line);
  $$->firstChild = $1; }
  ;

%%

void yyerror(char* msg) {
  fprintf(stderr, "Error type B at line %d: %s\n", yylineno, msg);
  syntaxErrors += 1;
}
/*
void preOrder(struct TreeNode* root, int layer) {
  if(root && !(root->type == 1 && root->firstChild == NULL)) {
    for (int i = 0; i < layer; ++i) {
      printf("  ");
    }
    if(root->type == 1) {
      if(root->firstChild != NULL)
        printf("%s (%d)\n", root->name, root->line);
    } else if (strcmp(root->name, "ID") == 0) {
      printf("%s: %s\n", root->name, root->exp.str);
    } else if (strcmp(root->name, "TYPE") == 0) {
      printf("%s: %s\n", root->name, root->exp.str);
    } else if (strcmp(root->name, "INT") == 0) {
      printf("%s: %d\n", root->name, root->exp.intVal);
    } else if (strcmp(root->name, "FLOAT") == 0) {
      printf("%s: %f\n", root->name, root->exp.floatVal);
    } else {
      printf("%s\n", root->name);
    }
    struct TreeNode* temp = root->firstChild;
    while(temp) {
      preOrder(temp, layer+1);
      temp = temp->nextSibling;
    }
  }
}
*/
void printTree()
{
  if(syntaxErrors == 0 && lexErrors == 0) 
    preOrder(head, 0);
}
