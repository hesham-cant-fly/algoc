cmake_minimum_required(VERSION 3.25)
project(algoc)

set(TARGET algoc)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_C_STANDARD 23)

file(GLOB_RECURSE C_SRC CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c")

if (MSVC)
  add_compile_options(/W4)
else()
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

add_definitions(-Dfalse=0 -Dtrue=1)
add_executable(${TARGET} main.c ${C_SRC})
target_include_directories(${TARGET} PUBLIC include/)
