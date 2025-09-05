#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define FIRST_DIM 4
#define SECOND_DIM 5
#define THIRD_DIM 10

int main(int argc, char *argv[])
{
  if (argc != 2)
  {
    printf("Uso: %s <numero>\n", argv[0]);
    return 1;
  }

  long n = atoi(argv[1]);

  long a = n % FIRST_DIM;
  long b = (n / FIRST_DIM) % SECOND_DIM;
  long c = n / (FIRST_DIM * SECOND_DIM);

  printf("%ld,%ld,%ld\n", a, b, c);
  return 0;
}