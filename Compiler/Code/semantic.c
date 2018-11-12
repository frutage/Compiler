#include "semantic.h"
#include "avltree.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

// Debug
void print_type(Type type) {
  if(type->kind == BASIC) {
    if(type->u.basic == INT_)
      printf("\ntype:int\n");
    else if(type->u.basic == FLOAT_)
      printf("\ntype:float\n");
    else
      printf("error\n");
  } else if (type->kind == STRUCTURE) {
    FieldList field = type->u.structure;
    int i = 1;
    printf("\ntype:struct---------\n");
    while(field != NULL) {
     printf("field_%d: %s with type \n", i, field->name);
     print_type(field->type);
     field = field->tail;
     i++;
    }

  } else {
    printf("\ntype:array---------\n");
    printf("Size %d with type \n", type->u.array.size);
    print_type(type->u.array.elem);
  }
}

// The pointer "CUR" always point to the current symbol table
stNode* stack, *cur;

/* The .c is used for semantic parsing.
 * It will traverse the syntax tree and add information to symbol table.
 * The symbol table is organized in AVL Tree, each node contains name and type.
 */

void enterInnerScope() {
//  printf("enter inner scope\n");
  cur->next = (stNode*)malloc(sizeof(stNode)); 
  cur->next->pre = cur;
  cur = cur->next;
  cur->tree = NULL;
}

void exitInnerScope() {
//  printf("exit inner scope\n");
  stNode* last = cur;
  cur = cur->pre;
  cur->next = NULL;
  free(last);
}

void semanticParser(TreeNode* head) {
  stack = (stNode*)malloc(sizeof(stNode));
  stack->tree = NULL;
  cur = stack;
  // Program -> ExtDefList
  TreeNode* extDeflist = head->firstChild;
  parseExtDeflist(extDeflist);
}

void parseExtDeflist(TreeNode* extDeflist) {
  if (extDeflist->firstChild == NULL) return;
  TreeNode* extDef = extDeflist->firstChild;
  Type type = parseSpecifier(extDef->firstChild);
 // print_type(type);

  TreeNode* second = extDef->firstChild->nextSibling;
  if (second->type != 0) {
    if (strcmp(second->name, "FunDec") == 0) {
      // ExtDef -> Specifier FunDec CompSt
      parseFunDec(type, second);
      parseCompSt(type, second->nextSibling);
      exitInnerScope();
    } else {
      // ExtDef -> Specifier ExtDecList SEMI
      parseExtDeclist(type, second);
    }
  }
  parseExtDeflist(extDeflist->firstChild->nextSibling);
}

void parseExtDeclist(Type type, TreeNode* extDeflist) {
  TreeNode* vardec = extDeflist->firstChild;
  FieldList field = addTypeToVar(type, vardec, true);
  if (vardec->nextSibling != NULL) {
    parseExtDeclist(type, vardec->nextSibling->nextSibling);
  }
}

Type parseSpecifier(TreeNode* Spec) {
  TreeNode* child = Spec->firstChild;

  if (strcmp(child->name, "TYPE") == 0) {
    // Construct a basic type.
    Type type = (Type)malloc(sizeof(struct Type_));
    type->kind = BASIC;
    if (strcmp(child->exp.str, "int") == 0) {
      type->u.basic = INT_;
    } else if (strcmp(child->exp.str, "float") == 0) {
      type->u.basic = FLOAT_;
    } else {
      printf("Unknown basic type!\n");
    }
    return type;
  } else {
    // Child is structSpecifier.
    return parseStructSpecifier(child);
  }
}

Type parseStructSpecifier(TreeNode* StructSpecifier) {
  TreeNode* tag = StructSpecifier->firstChild->nextSibling;
  Type type = NULL;

  if (strcmp(tag->name, "OptTag") == 0) {
    type = (Type)malloc(sizeof(struct Type_));
    type->kind = STRUCTURE;
    enterInnerScope();
    type->u.structure = getFields(tag->nextSibling->nextSibling, false);
    exitInnerScope();
    if (tag->firstChild != NULL) {
      // Define: Struct ID LC Deflist RC
      Symbol sym;
      sym.kind = STRUCT_;
      strcpy(sym.name, tag->firstChild->exp.str);
      sym.info.type = type;
      if (search_sym(cur, sym) == NULL) {
        cur->tree = avltree_insertNode(cur->tree, sym);
      } else {
        printf("Error type 16 at Line %d: Duplicated name \"%s\".\n", tag->line, sym.name);
      }
    }  
  } else {
    // Declare: Struct Tag(ID)
    Symbol sym;
    sym.kind = STRUCT_;
    strcpy(sym.name, tag->firstChild->exp.str);
    avlnode* n = search_sym(cur, sym);
    if(n == NULL) {
      printf("Error type 17 at Line %d: Undefined structure \"%s\".\n", tag->firstChild->line, sym.name);
      type = (Type)malloc(sizeof(struct Type_));
      type->kind = STRUCTURE;
      // The filed "structure" is NULL indicates it's not a deined structure variable.
      type->u.structure = NULL;
    } else {
      type = n->key.info.type;
    }
  }
  return type;
}

FieldList getFields(TreeNode* deflist, bool isCompSt) {
  if (deflist->firstChild == NULL) {
    return NULL;
  }
  // DefList->Def DefList

  FieldList fields = NULL;
  TreeNode* def = deflist->firstChild;
  TreeNode* sublist = def->nextSibling;
  
  // Get fieldlist for the first "def"
  Type type = parseSpecifier(def->firstChild);
  fields = addTypeToDeclist(type, def->firstChild->nextSibling, isCompSt);

  FieldList Tail = fields;
  while (Tail->tail != NULL) {
    Tail = Tail->tail;
  }
  Tail->tail = getFields(sublist, isCompSt);
  return fields;
}

FieldList addTypeToDeclist(Type type, TreeNode* declist, bool isCompSt) {
  TreeNode* dec = declist->firstChild;
  TreeNode* vardec =  dec->firstChild;
  FieldList field = addTypeToVar(type, vardec, isCompSt);
  if (vardec->nextSibling != NULL) {
    if (!isCompSt) {
      printf("Error type 15 at Line %d : Initialize a field of structure.\n", vardec->line);
    } else {
      Type t = checkExp(vardec->nextSibling->nextSibling);
      if (t != NULL && !isTypeEqual(t, type)) {
        printf("Error type 5 at Line %d: Type msmatched for assignment.\n", vardec->line);
      }
    }
  }

  if (dec->nextSibling != NULL) {
    field->tail = addTypeToDeclist(type, dec->nextSibling->nextSibling, isCompSt);
  }
  return field;
}

FieldList addTypeToVar(Type type, TreeNode* vardec, bool isCompSt) {
  TreeNode* child = vardec->firstChild;
  FieldList field = NULL;
  if (child->type == 0) {
    // VarDec->ID
    Symbol sym;
    sym.kind = (type->kind == STRUCTURE) ? STRUCT_ : VAR;
    sym.info.type = type;
    strcpy(sym.name, child->exp.str);
    if (search_node(cur->tree, sym) == NULL) {
      cur->tree = avltree_insertNode(cur->tree, sym);
//      printf("Hello! ADD a new Node %s\n", sym.name);
    } else if (isCompSt){
        printf("Error type 3 at Line %d: Redefined variable \"%s\".\n", child->line, sym.name);
    } else {
      printf("Error type 15 at Line %d: Redefined field \"%s\".\n", child->line, sym.name);
    }

    // whether construct fields when error?
    field = (FieldList)malloc(sizeof(struct FieldList_));
    strcpy(field->name, child->exp.str);
    field->type = type;
    field->tail = NULL;
    return field;
  } else {
    // VarDec->VarDec [ INT ]
    Type arrayType = (Type)malloc(sizeof(struct Type_)) ;
    arrayType->kind = ARRAY;
    arrayType->u.array.elem = type;
    arrayType->u.array.size = child->nextSibling->nextSibling->exp.intVal;
    return addTypeToVar(arrayType, child, isCompSt);
  }
}

void parseFunDec(Type retType, TreeNode* funDec) {
  TreeNode* funName = funDec->firstChild;
  TreeNode* varList = funName->nextSibling->nextSibling;
  Func func = NULL;
  func = (Func)malloc(sizeof(struct Func_));
  if(varList->type == 0)
    varList = NULL;
  // Add parameters into inner scope.
  enterInnerScope();
  func->argsList = getArgs(varList);
  func->retType = retType;
  func->lineno = funName->line;
  func->state = DEFINED;
  
  // Insert to symbol table.
  Symbol sym;
  sym.kind = FUNC;
  strcpy(sym.name, funName->exp.str);
  sym.info.func = func;

  // Add the function name to external scope.
  cur = cur->pre;
  if (search_sym(cur, sym) == NULL) {
    cur->tree = avltree_insertNode(cur->tree, sym);
  } else {
    printf("Error type 4 at Line %d: Redefined function \"%s\".\n", funName->line, sym.name);
  }
  cur = cur->next;
}

FieldList getArgs(TreeNode* varlist) {
  if (varlist == NULL)
    return NULL;
  TreeNode* param = varlist->firstChild;
  Type type = parseSpecifier(param->firstChild);
  FieldList field = addTypeToVar(type, param->firstChild->nextSibling, true);

  if (param->nextSibling != NULL) {
    FieldList Tail = field;
    while(Tail->tail != NULL) {
      Tail = Tail->tail;
    }
    Tail->tail = getArgs(param->nextSibling->nextSibling);
  }
  return field;
}

void parseExtDecList(Type type, TreeNode* extdeclist) {
  TreeNode* vardec = extdeclist->firstChild;
  // Use the side effect of this function to add symbol to symbol table;
  FieldList field = addTypeToVar(type, vardec, true);
  free(field);
  if (vardec->nextSibling != NULL) {
    parseExtDecList(type, vardec->nextSibling->nextSibling);
  }
}

void parseCompSt(Type retType, TreeNode* CompSt) {
  TreeNode* deflist = CompSt->firstChild->nextSibling;
  FieldList fields = getFields(deflist, true);
  TreeNode* stmtlist = deflist->nextSibling;
  parseStmtlist(retType, stmtlist);
}

void parseStmtlist(Type retType, TreeNode* Stmtlist) {
  if (Stmtlist->firstChild == NULL) return;
  parseStmt(retType, Stmtlist->firstChild);
  parseStmtlist(retType, Stmtlist->firstChild->nextSibling);
}

void parseStmt(Type retType, TreeNode* stmt) {
  TreeNode* first = stmt->firstChild;
  if (strcmp(first->name, "CompSt") == 0) {
    // Stmt -> CompSt
    enterInnerScope();
    parseCompSt(retType, first);
    exitInnerScope();
  } else if (strcmp(first->name, "RETURN") == 0) {
    // Stmt -> RETURN Exp SEMI
    if (!isTypeEqual(checkExp(first->nextSibling), retType)) {
      printf ("Error type 8 at Line %d: Type mismatched for return.\n", first->line);
    }
  } else if (strcmp(first->name, "IF") == 0 || strcmp(first->name, "WHILE") == 0) {
    // Stmt -> IF LP Exp RP Stmt (ELSE Stmt)
    TreeNode* exp = first->nextSibling->nextSibling;
    Type expType = checkExp(exp);
    if (expType != NULL && (expType->kind != BASIC || expType->u.basic != INT_)) {
      printf ("Error type 7 at Line %d: Type mismatched for the condition of if/while-clause.\n", first->line);
    }

    TreeNode* stmt = exp->nextSibling->nextSibling;
    parseStmt(retType, stmt);
    if (stmt->nextSibling != NULL) {
      parseStmt(retType, stmt->nextSibling->nextSibling);
    }

  } else {
    // Stmt-> Exp SEMI
    Type tmp = checkExp(first);
  }
}

Type checkExp(TreeNode* Exp) {
  TreeNode* first = Exp->firstChild;
  Type ret;

  if(strcmp(first->name, "Exp") == 0) {
    ret = checkExp(first);
    TreeNode* second = first->nextSibling;
    TreeNode* third = second->nextSibling;	
    if (strcmp(third->name, "Exp") == 0 && third->nextSibling == NULL) {
      // Expression like "Exp [OP] Exp"

      if (strcmp(second->name, "ASSIGNOP") == 0) {
        // Exp -> Exp ASSIGNOP Exp
        if (!isLeftValExp(first))
          printf("Error type 6 at Line %d: The left-hand side of an assignment must be a variable.\n", first->line);

        if (!isTypeEqual(ret, checkExp(third))) {
          printf("Error type 5 at Line %d: Type mismatched for assignment.\n", first->line);
          ret = NULL;
        }
      } else if (strcmp(second->name, "AND") == 0 || strcmp(second->name, "OR") == 0) {
        // Exp -> Exp AND/OR Exp
        if ((ret != NULL && !(ret->kind == BASIC && ret->u.basic == INT_)) || !isTypeEqual(ret, checkExp(third)))
        {
          printf("Error type 7 at Line %d: Type mismatched for operands.\n", first->line);
          ret = NULL;
        }
      } else {
        // Exp -> Exp RELOP/PLUS/MINUS/STAR/DIV Exp
        if ((ret != NULL && ret->kind != BASIC) || !isTypeEqual(ret, checkExp(third))) {
          printf("Error type 7 at Line %d: Type mismatched for operands.\n", first->line);
          ret = NULL;
        } 
      }
    } else if (third->nextSibling == NULL) {
      //Exp -> Exp DOT ID
      if (ret != NULL) {
        if (ret->kind != STRUCTURE) {
          printf("Error type 13 at Line %d: Illegal use of \".\".\n", first->line);
          ret = NULL;
        } else {
          FieldList field = searchField(ret->u.structure, third->exp.str);
          if (field == NULL) {
            printf("Error type 14 at Line %d: Non-existent field \"%s\".\n", third->line, third->exp.str);
            ret = NULL;
          } else {
            ret = field->type;
          }
        }
      }
    } else {
      // Exp -> Exp LB Exp RB
      if (ret != NULL) {
        if (ret->kind != ARRAY) {
          printf("Error type 10 at Line %d: Variable is not an array.\n", first->line);
          ret = NULL;
        } else {
          Type index = checkExp(third);
          if (index == NULL || index->kind != BASIC || index->u.basic != INT_)
            printf("Error type 12 at Line %d: Array index is not an integer.\n", third->line);
          ret = ret->u.array.elem;
        }
      }
    }
  } else if (strcmp(first->name, "ID") == 0) {
    TreeNode* second = first->nextSibling;
    Symbol sym;
    strcpy(sym.name, first->exp.str);
    // Search th symbol table for the variable when use it.
    avlnode* n = search_sym(cur, sym);

    if (second == NULL) {
      // Exp -> ID
      if (n == NULL) {
        printf("Error type 1 at Line %d: Undefined variable \"%s\".\n", first->line, first->exp.str);
        ret = NULL;
      } else {
        ret = n->key.info.type;
      }
    } else {
      // Exp -> ID LP (Args) RP
      TreeNode* args = second->nextSibling;
      if (args->type == 0)
        args = NULL;

      if (n == NULL) {
        printf("Error type 2 at Line %d: Undefined function \"%s\".\n", first->line, first->exp.str);
        ret = NULL;
      } else if (n->key.kind != FUNC) {
        printf("Error type 11 at Line %d: \"%s\" is not a function.\n", first->line, first->exp.str);
      } else if (!checkArgs(n->key.info.func->argsList, args)) {
        printf("Error type 9 at Line %d: Function \"%s\" is not applicable for arguments.\n", first->line, first->exp.str);
        ret = NULL;
      } else {
        ret = n->key.info.func->retType;
      }
    }
  } else if (strcmp(first->name, "INT") == 0) {
    ret = (Type)malloc(sizeof(struct Type_));
    ret->kind = BASIC;
    ret->u.basic = INT_;
  } else if (strcmp(first->name, "FLOAT") == 0) {
    ret = (Type)malloc(sizeof(struct Type_));
    ret->kind = BASIC;
    ret->u.basic = FLOAT_;
  } else if (strcmp(first->name, "LP") == 0) {
    // Exp -> LP Exp RP
    ret = checkExp(first->nextSibling);
  } else if (strcmp(first->name, "MINUS") == 0) {
    // Exp -> MINUS Exp
    ret = checkExp(first->nextSibling);
    if (ret != NULL && ret->kind != BASIC) {
      printf("Error type 7 at Line %d: Type mismatched for operator.\n", first->line);
      ret = NULL;
    }
  } else if (strcmp(first->name, "NOT") == 0) {
    // Exp -> NOT Exp
    ret = checkExp(first->nextSibling);
    if (ret != NULL && (ret->kind != BASIC || ret->u.basic != INT_)) {
      printf("Error type 7 at Line %d: Type mismatched for operator.\n", first->line);
      ret = NULL;
    }
  }
  return ret;
}

bool isLeftValExp(TreeNode* Exp) {
  TreeNode* first = Exp->firstChild;
  if (strcmp(first->name, "Exp") == 0) {
    char* second = first->nextSibling->name;
    if (strcmp(second, "ASSIGNOP") == 0 || strcmp(second, "LB") == 0 | strcmp(second, "DOT") == 0) {
      return true;
    }
    return false;
  } else if (strcmp(first->name, "ID") == 0) {
    if (first->nextSibling == NULL) {
      return true;
    }
    return false;
  } else if (strcmp(first->name, "LP") == 0) {
    return isLeftValExp(first->nextSibling);
  } else {
    return false;
  }
}


bool isTypeEqual(Type a, Type b) {
  if(a == NULL || b == NULL)
    return true;
  if (a->kind != b->kind)
    return false;

  switch(a->kind) {
    case BASIC: return a->u.basic == b->u.basic;
      break;
    case ARRAY: return isTypeEqual(a->u.array.elem, b->u.array.elem); 
      break;
    case STRUCTURE: return isStructEqual(a->u.structure, b->u.structure);
      break;
    default: {
      printf("Unknown type!\n");
      return false;
    }
  }
}

bool isStructEqual(FieldList a, FieldList b) {
  if (a == NULL && b == NULL) 
    return true;
  if (a == NULL | b == NULL)
    return false;
  
  if(!isTypeEqual(a->type, b->type)) {
    return false;
  } else {
    return isStructEqual(a->tail, b->tail);
  }
}

FieldList searchField(FieldList list, char* name) {
  FieldList ptr = list;
  while (ptr != NULL) {
    if (strcmp(ptr->name, name) == 0)
      return ptr;
    ptr = ptr->tail;
  }
  return NULL;
}

bool checkArgs(FieldList Args, TreeNode* actual) {
  if (actual == NULL && Args == NULL)
    return true;
  if (actual == NULL || Args == NULL)
    return false;
  Type type1 = checkExp(actual->firstChild);
  if (!isTypeEqual(type1, Args->type)) {
    return false;
  } else {
    TreeNode* next = (actual->firstChild->nextSibling == NULL) ? NULL : (actual->firstChild->nextSibling->nextSibling);
    return checkArgs(Args->tail, next);
  }
}

