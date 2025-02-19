#include "lexer.h"
#include "Vector.h"
#include "common.h"
#include "tokens.h"
#include <ctype.h>

extern int err_state;

static char peek(const Lexer *self);
static char advance(Lexer *self);

static void add_token(Lexer *self, TokenType tp);
static _Bool is_at_end(Lexer *self);
static void scan_lexem(Lexer *self);
static void scan_number(Lexer *self);

void Lexer_init(Lexer *self, const char *content, const size_t content_size) {
  self->content = content;
  self->content_size = content_size;
  self->current = 0;
  self->start = 0;
  self->line = 0;
  self->column = 0;
  VectorToken_init(&self->tokens);
}

void Lexer_deinit(Lexer *self) {
  VectorToken_deinit(&self->tokens);
  self->current = 0;
  self->start = 0;
  self->line = 0;
  self->column = 0;
}

VectorToken Lexer_scan(Lexer *self) {
  self->start = 0;
  self->current = 0;
  self->line = 1;
  self->column = 1;

  while (is_at_end(self)) {
    self->start = self->current;
    scan_lexem(self);
  }

  return self->tokens;
}

static void scan_lexem(Lexer *self) {
  char ch = advance(self);
  switch (ch) {
  case '+':
    add_token(self, TOKEN_PLUS);
    break;
  case '-':
    add_token(self, TOKEN_MINUS);
    break;
  case '*':
    add_token(self, TOKEN_STAR);
    break;
  case '/':
    add_token(self, TOKEN_FSLASH);
    break;
  case '(':
    add_token(self, TOKEN_OPEN_PAREN);
    break;
  case ')':
    add_token(self, TOKEN_CLOSE_PAREN);
    break;
  case '"':
    todo();
    break;
  default:
    if (isdigit(ch)) {
      scan_number(self);
    }
    break;
  }
}

static void scan_number(Lexer *self) {
  while (isdigit(peek(self)))
    advance(self);

  add_token(self, TOKEN_NUMIRIC_LIT);
}

static char peek(const Lexer *self) { return self->content[self->current]; }
static char advance(Lexer *self) { return self->content[self->current - 1]; }

static void add_token(Lexer *self, TokenType tp) {
  Token tk = {.tp = tp,
              .lexem = make_string_view(self->content, self->start,
                                        self->current - self->start),
              .start = self->start,
              .end = self->current,
              .line = self->line,
              .column = self->column};
  VectorToken_add(&self->tokens, tk);
}

static _Bool is_at_end(Lexer *self) {
  return self->current >= self->content_size;
}
