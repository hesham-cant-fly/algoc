#ifndef __STRING_VIEW_H
#define __STRING_VIEW_H

#include <stdio.h>

typedef struct StringView {
  const char *const data;
  size_t length;
} StringView;

StringView make_string_view(const char *str, const size_t at,
                            const size_t length);

#endif
