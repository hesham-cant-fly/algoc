#ifndef __COMMON_H
#define __COMMON_H

#include <assert.h>
#include <stdlib.h>

#define create(tp) malloc(sizeof(tp))
#define alloc(tp, amount) malloc(sizeof(tp) * amount);
#define todo() assert(false)
#define and &&
#define or ||

#endif //! __COMMON_H
