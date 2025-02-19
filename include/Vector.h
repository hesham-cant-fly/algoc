#ifndef __VECTOR_H
#define __VECTOR_H

#include <stddef.h>
#include "tokens.h"

#define INITIAL_CAP 10

typedef struct VectorToken {
  size_t len;
  size_t cap;
  Token *data;
} VectorToken;

void VectorToken_init(VectorToken *self);
void VectorToken_deinit(VectorToken *self);
void VectorToken_add(VectorToken *self, Token value);
Token VectorToken_get(VectorToken *self, size_t index);
void VectorToken_set(VectorToken *self, size_t index, Token value);


#endif
