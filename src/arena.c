#include "arena.h"
#include "common.h"
#include <assert.h>
#include <inttypes.h>
#include <stddef.h>
#include <stdlib.h>

static size_t align_up(size_t size, size_t alignment);

Arena make_arena(void) { return (Arena){nullptr}; }

void *arena_alloc(Arena *self, size_t size) {
  size = align_up(size, ARENA_ALIGNMENT);

  if (self->current != nullptr) {
    ArenaBlock *current = self->current;
    if (current->used + size <= current->cap) {
      void *ptr = current->data + current->used;
      current->used += size;
      return ptr;
    }
  }

  size_t block_size =
      sizeof(ArenaBlock) + (size > ARENA_BLOCK_SIZE ? size : ARENA_BLOCK_SIZE);

  ArenaBlock *block = malloc(block_size);
  assert(block != nullptr);

  block->next = self->current;
  block->cap = block_size - sizeof(ArenaBlock);
  block->used = size;

  self->current = block;

  return block->data;
}

void arena_free(Arena *self) {
  ArenaBlock *block = self->current;
  while (block) {
    ArenaBlock *prev = block->next;
    free(block);
    block = prev;
  }
  self->current = nullptr;
}

static size_t align_up(size_t size, size_t alignment) {
  return (size + alignment - 1) & ~(alignment - 1);
}
