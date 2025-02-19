
all: build-exe run

sync:
	cd generics && deno run ./main.ts;
	cmake -S . -B build/ -G "Unix Makefiles"

build-exe:
	cd build && make

run:
	cd build && ./algoc
