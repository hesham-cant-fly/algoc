#ifndef __LEXER_H
#define __LEXER_H

#include "Vector.h"

typedef struct Lexer {
  VectorToken tokens;
  const char *content;
  size_t content_size, start, current, line, column;
} Lexer;

void Lexer_init(Lexer *self, const char *content, const size_t content_size);
void Lexer_deinit(Lexer *self);

VectorToken Lexer_scan(Lexer *self);

#endif
