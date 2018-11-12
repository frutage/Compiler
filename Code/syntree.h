#ifndef _SYNTREE_H_
#define _SYNTREE_H_

union Exp {
  int intVal;
  float floatVal;
  char* str;
};

/* Tree node for syntax tree */
typedef struct TreeNode {
  char* name;
  union Exp exp;
  int line;
  /* 1 indicates non-terminal 
  *  0 indicates terminal
  */
  int type; 
  struct TreeNode* firstChild;
  struct TreeNode* nextSibling;
  struct TreeNode* farther;
}TreeNode;

TreeNode* createNode(char* name, int type, int line);

void preOrder(struct TreeNode* root, int layer);

#endif
