import { Name } from "./common.ts";


export async function make(tps: Name[], outPath: string) {
    const vectorHeaders: string[] = [];
    const vectorSources: string[] = [];

    for (let e of tps) {
        vectorHeaders.push(generateHeader(e.tp, e.san));
        vectorSources.push(generateSource(e.tp, e.san));
    }

    await save(
        makeHeader(vectorHeaders),
        makeSource(vectorSources),
        outPath
    );
}

export function makeHeader(a: string[]): string {
    return `#ifndef __VECTOR_H
#define __VECTOR_H

#include <stddef.h>
#include "tokens.h"

#define INITIAL_CAP 10

${a.join("\n/********************************************************************************/\n\n")}

#endif
`;
}

export function makeSource(a: string[]): string {
    return `#include "Vector.h"
#include <stdlib.h>
#include <stddef.h>
#include <assert.h>
#include "tokens.h"

${a.join("\n/********************************************************************************/\n\n")}

`;
}

export async function save(header: string, source: string, outPath: string) {
    await Deno.writeTextFile(`../include/${outPath}.h`, header);
    await Deno.writeTextFile(`../src/${outPath}.c`, source);
}

export function generateHeader(tp: string, san: string): string {
    const typeName = `Vector${san}`;
    return `typedef struct ${typeName} {
  size_t len;
  size_t cap;
  ${tp} *data;
} ${typeName};

void ${typeName}_init(${typeName} *self);
void ${typeName}_deinit(${typeName} *self);
void ${typeName}_add(${typeName} *self, ${tp} value);
${tp} ${typeName}_get(${typeName} *self, size_t index);
void ${typeName}_set(${typeName} *self, size_t index, ${tp} value);
`;
}

export function generateSource(tp: string, san: string): string {
    const typeName = `Vector${san}`;
    return `void ${typeName}_init(${typeName} *self) {
    self->cap  = INITIAL_CAP;
    self->len  = 0;
    self->data = (${tp}*)malloc(self->cap * sizeof(${tp}));
    assert(self->data != nullptr);
}

void ${typeName}_deinit(${typeName} *self) {
    free(self->data);
    self->data = nullptr;
    self->len  = 0;
    self->cap  = 0;
}

void ${typeName}_add(${typeName} *self, ${tp} value) {
  if (self->len >= self->cap) {
    self->cap *= 1.5;
    self->data = realloc(self->data, self->cap * sizeof(${tp}));
    assert(self->data != nullptr);
  }
  self->data[self->len] = value;
  self->len++;
}

${tp} ${typeName}_get(${typeName} *self, size_t index) {
  assert(index < self->len);
  return self->data[index];
}

void ${typeName}_set(${typeName} *self, size_t index, ${tp} value) {
  assert(index < self->len);
  self->data[index] = value;
}
`;
}
