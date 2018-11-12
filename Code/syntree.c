#include "syntree.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

TreeNode* createNode(char* name, int type, int line) {
  struct TreeNode* h = malloc(sizeof(TreeNode));
  h->name = name;
  h->type = type;
  h->line = line;
  h->nextSibling = NULL;
  h->firstChild = NULL;
  return h;
}

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

