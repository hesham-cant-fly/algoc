#ifndef __ARENA_H
#define __ARENA_H

#include <stdalign.h>
#include <stddef.h>

#define ARENA_BLOCK_SIZE 4069
#define ARENA_ALIGNMENT alignof(max_align_t)

typedef struct ArenaBlock {
  struct ArenaBlock *next;
  size_t cap, used;
  unsigned char data[];
} ArenaBlock;

typedef struct Arena {
  ArenaBlock *current;
} Arena;

Arena make_arena(void);
void *arena_allocat(Arena *self, size_t size);
void arena_free(Arena *self);

#endif
