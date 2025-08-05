#include <ctype.h>
#include <stdio.h>

int main() {
  char ch1 = 'A';
  char ch2 = '\n';
  char ch3 = ' ';

  if (isprint(ch1)) {
    printf("'%c' is a printable character.\n", ch1);
  } else {
    printf("'%c' is not a printable character.\n", ch1);
  }

  if (isprint(ch2)) {
    printf("'%c' is a printable character.\n", ch2);
  } else {
    printf("'\\n' is not a printable character.\n"); // Print '\n' explicitly
  }

  if (isprint(ch3)) {
    printf("'%c' is a printable character.\n", ch3);
  } else {
    printf("'%c' is not a printable character.\n", ch3);
  }

  return 0;
}
