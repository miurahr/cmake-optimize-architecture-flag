cmake_minimum_required (VERSION 3.5)
project(example VERSION 1.0 LANGUAGES C)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_MODULE_PATH  ${CMAKE_CURRENT_LIST_DIR}/Modules)

include(OptimizeArchitectureFlag)
optimize_architecture_flag(ARCHITECTURE_FLAG)

add_executable(example example.c)
target_compile_options(example PRIVATE ${ARCHITECTURE_FLAG})

message(STATUS "add to CFLAG: ${ARCHITECTURE_FLAG}")

# vim: ts=4 sw=4 sts=4 et
