#ifndef __TOKENS_H
#define __TOKENS_H

#include "string_view.h"
#include <stdio.h>

typedef enum TokenType {
  TOKEN_PLUS,   // '+'
  TOKEN_MINUS,  // '-'
  TOKEN_STAR,   // '*'
  TOKEN_FSLASH, // '/'

  TOKEN_OPEN_PAREN,  // '('
  TOKEN_CLOSE_PAREN, // ')'

  // Literals
  TOKEN_STRING_LIT,  // any thing that goes inside of those "" or those ''
  TOKEN_NUMIRIC_LIT, // any real number
} TokenType;

typedef struct Token {
  TokenType tp;
  StringView lexem;
  size_t start, end, line, column;
} Token;

void TokenType_print(const TokenType self);
void Token_print(const Token *const self);

#endif
