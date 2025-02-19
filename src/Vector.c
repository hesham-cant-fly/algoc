#include "Vector.h"
#include <stdlib.h>
#include <stddef.h>
#include <assert.h>
#include "tokens.h"

void VectorToken_init(VectorToken *self) {
    self->cap  = INITIAL_CAP;
    self->len  = 0;
    self->data = (Token*)malloc(self->cap * sizeof(Token));
    assert(self->data != nullptr);
}

void VectorToken_deinit(VectorToken *self) {
    free(self->data);
    self->data = nullptr;
    self->len  = 0;
    self->cap  = 0;
}

void VectorToken_add(VectorToken *self, Token value) {
  if (self->len >= self->cap) {
    self->cap *= 1.5;
    self->data = realloc(self->data, self->cap * sizeof(Token));
    assert(self->data != nullptr);
  }
  self->data[self->len] = value;
  self->len++;
}

Token VectorToken_get(VectorToken *self, size_t index) {
  assert(index < self->len);
  return self->data[index];
}

void VectorToken_set(VectorToken *self, size_t index, Token value) {
  assert(index < self->len);
  self->data[index] = value;
}


