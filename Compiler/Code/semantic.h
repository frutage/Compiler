#ifndef _SEMANTIC_H_
#define _SEMANTIC_H_
#define MAX_SIZE 32
#include "syntree.h"
typedef enum { false, true} bool;
typedef struct Type_* Type;
typedef struct FieldList_* FieldList;
typedef struct Func_* Func;

struct Type_ {
  enum { BASIC, ARRAY, STRUCTURE } kind;
  union {
    enum { INT_, FLOAT_ } basic;
    struct {
      Type elem;
      int size;
    } array;
    FieldList structure;
  } u;
};

struct FieldList_ {
  char name[MAX_SIZE];
  Type type;
  FieldList tail;
};

struct Func_ {
  enum { UNDEFINED, DEFINED } state;
  FieldList argsList;
  Type retType; 
  int lineno;
};

typedef struct Symbol_ Symbol,elementType;
struct Symbol_ {
  enum { VAR, FUNC, STRUCT_ } kind;
  char name[MAX_SIZE];
  union {
    Type type;
    Func func;
  } info; 
};

Type parseSpecifier(TreeNode* Spec);
Type parseStructSpecifier(TreeNode* Struct);
void semanticParse();
void parseExtDeflist(TreeNode* extDeflist);
void parseExtDeclist(Type type, TreeNode* extDeclist);
void parseCompSt(Type retType, TreeNode* CompSt);
void parseStmtlist(Type retType, TreeNode* Stmtlist);
void parseStmt(Type retType, TreeNode* stmt);
FieldList getFields(TreeNode* deflist, bool isCompSt);
FieldList searchField(FieldList list, char* name);
FieldList addTypeToDeclist(Type type, TreeNode* declist, bool isCompSt);
FieldList addTypeToVar(Type type, TreeNode* vardec, bool isCompSt);
void parseExtDecList(Type type, TreeNode* extdeclist);
void parseFunDec(Type retType, TreeNode* FunDec);
FieldList getArgs(TreeNode* varlist);
Type checkExp(TreeNode* Exp);
bool isLeftValExp(TreeNode* Exp);
bool isTypeEqual(Type a, Type b);
bool isStructEqual(FieldList a, FieldList b);
bool checkArgs(FieldList Args, TreeNode* actual);
void enterInnerScope();
void exitInnerScope();

#endif
