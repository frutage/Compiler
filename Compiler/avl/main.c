#include "avltree.h"
#include <string.h>
#include <stdio.h>

int main()
{
  elementType key;
  printf("enter it!\n");
  strcpy(key.name, "hello");
  printf("strcpy!\n");
  avltree tree = NULL;
  tree = avltree_insertNode(tree, key);
  printf("hello!\n");
  print_avltree(tree, key, 0);

  elementType key2;
  strcpy(key2.name, "world");
  tree = avltree_insertNode(tree, key2);
  print_avltree(tree, key, 0);

  elementType key3;
  strcpy(key3.name, "hfll");
  tree = avltree_insertNode(tree, key3);
//  if(tree == NULL)
//    printf("NULL\n");
  print_avltree(tree, key, 0);

  return 0;
}
