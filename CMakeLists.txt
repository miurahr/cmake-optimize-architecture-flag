cmake_minimum_required (VERSION 3.5)
project(example VERSION 1.0 LANGUAGES C)

include("${CMAKE_CURRENT_LIST_DIR}/OptimizeArchitectureFlags.cmake")
optimize_architecture_flags(ARCHITECTURE_FLAG)

message(STATUS "Add follwoings to compile options: ${ARCHITECTURE_FLAG}")

add_executable(example example.c)
target_compile_options(example PRIVATE ${ARCHITECTURE_FLAG})

# vim: ts=4 sw=4 sts=4 et
