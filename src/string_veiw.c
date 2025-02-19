#include "string_view.h"
#include <stdio.h>

StringView make_string_view(const char *str, const size_t at,
                            const size_t length) {
  return (StringView){str + at, length};
}
