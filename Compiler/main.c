#include <stdio.h>
#include<stdlib.h>
#include "avltree.h"

int main()
{
  avltree tree;
  tree = avltree_insertNode(tree, 1);
  print_avltree(tree, 1, 0);
  printf("\n");
  tree = avltree_insertNode(tree,3);
  print_avltree(tree, 1, 0);
  printf("\n");
  tree = avltree_insertNode(tree,4);
  print_avltree(tree, 1, 0);
  printf("\n");
  tree = avltree_insertNode(tree,3);
  avltree_deleNode(tree, 4);
  print_avltree(tree, 1, 0);
  return 0;
}
