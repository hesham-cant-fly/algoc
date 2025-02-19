#include "Vector.h"
#include "lexer.h"
#include "tokens.h"
#include <string.h>

int err = 0;

int main(void) {
  const char *content = "1 + 4 / 87";
  Lexer l;
  Lexer_init(&l, content, strlen(content));
  VectorToken tokens = Lexer_scan(&l);
  for (size_t i = 0; i < tokens.len; i++) {
    Token item = VectorToken_get(&tokens, i);
    Token_print(&item);
  }
  Lexer_deinit(&l);
  return 0;
}
