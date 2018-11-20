cmake_minimum_required (VERSION 3.5)
project(ofa-example VERSION 1.0 LANGUAGES C)
set(CMAKE_MODULE_PATH  ${CMAKE_CURRENT_LIST_DIR}/../ ${CMAKE_CURRENT_LIST_DIR}/../Modules)

include(OptimizeArchitectureFlags)
optimize_architecture_flags(ARCHITECTURE_FLAG)

message(STATUS "Add follwoings to compile options: ${ARCHITECTURE_FLAG}")

add_executable(ofa-example example.c)
target_compile_options(ofa-example PRIVATE ${ARCHITECTURE_FLAG})

# vim: ts=4 sw=4 sts=4 et
