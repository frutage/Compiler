#ifndef _SEMANTIC_H_
#define _SEMANTIC_H_
#define MAX_SIZE 32

typedef struct Type_* Type;
typedef struct FieldList_* FieldList;
typedef struct Func_* Func;

struct Type_ {
  enum { BASIC, ARRAY, STRUCTURE } kind;
  union {
    enum { INT, FLOAT } basic;
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
  FieldList argsList;
  Type retType; 
  // definition 
  int lineno;
};

typedef struct Symbol_ Symbol, elementType;
struct Symbol_ {
  enum { VAR, FUNC, STRUCT } kind;
  char name[MAX_SIZE];
  union {
    Type type;
    Func func;
  } info;
};

#endif
