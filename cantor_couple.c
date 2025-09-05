#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main(int argc, char *argv[])
{
  if (argc != 2)
  {
    printf("Uso: %s <numero>\n", argv[0]);
    return 1;
  }

  long z = atoi(argv[1]);

  long n = floor((sqrt(8 * z + 1) - 1) / 2);
  long t = n * (n + 1) / 2;
  long k = z - t;
  printf("%ld,%ld\n", k, n - k);
  return 0;
}