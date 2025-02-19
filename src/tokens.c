
#include "tokens.h"
#include <assert.h>
#include <stddef.h>
#include <stdio.h>

void TokenType_print(const TokenType self) {
  switch (self) {
  case TOKEN_STRING_LIT:
    printf("TOKEN_STRING_LIT");
    break;
  case TOKEN_NUMIRIC_LIT:
    printf("TOKEN_NUMIRIC_LIT");
    break;
  default:
    assert(false);
  }
}

void Token_print(const Token *const self) {
  printf("Token { tp: ");
  TokenType_print(self->tp);
  printf(", lexem: \"%.*s\" }", (int)self->lexem.length, self->lexem.data);
}
