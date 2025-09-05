#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
  if (argc != 3)
  {
    fprintf(stderr, "Uso: %s x1 x2\n", argv[0]);
    return 1;
  }
  int x1 = atoi(argv[1]);
  int x2 = atoi(argv[2]);
  int sum = x1 + x2;
  int cantor = (sum * (sum + 1)) / 2 + x2;
  printf("%d\n", cantor);
  return 0;
}
