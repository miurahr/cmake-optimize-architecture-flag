cmake_minimum_required (VERSION 3.5)
project(ofa-example VERSION 1.0 LANGUAGES C)
set(CMAKE_MODULE_PATH  ${CMAKE_CURRENT_LIST_DIR}/../ ${CMAKE_CURRENT_LIST_DIR}/../Modules)

set(TARGET_ARCHITECTURE "auto" CACHE STRING "CPU architecture to optimize for. \
Using an incorrect setting here can result in crashes of the resulting binary because of invalid instructions used. \
Setting the value to \"auto\" will try to optimize for the architecture where cmake is called. \
Other supported values are: \"none\", \"generic\", \"core\", \"merom\" (65nm Core2), \
\"penryn\" (45nm Core2), \"nehalem\", \"westmere\", \"sandy-bridge\", \"ivy-bridge\", \
\"haswell\", \"broadwell\", \"skylake\", \"skylake-xeon\", \"kaby-lake\", \"cannonlake\", \"silvermont\", \
\"goldmont\", \"knl\" (Knights Landing), \"atom\", \"k8\", \"k8-sse3\", \"barcelona\", \
\"istanbul\", \"magny-cours\", \"bulldozer\", \"interlagos\", \"piledriver\", \
\"amd-14h\", \"amd-16h\", \"zen\".")

include(DetectCPUMicroArchitecture)
detect_cpu_micro_architecture(MARCH)
message(STATUS "Detected micro architecture: ${MARCH}")

include(GetCPUSIMDFeatures)
get_cpu_simd_features(fl ${MARCH})
message(STATUS "Detected feature list: ${fl}")

include(GetMarchCompilerOptions)
get_march_compiler_options(op ${MARCH})

include(OptimizeArchitectureFlags)
optimize_architecture_flags(ARCHITECTURE_FLAG TARGET_ARCHITECTURE ${MARCH})

message(STATUS "Add followings to compile options: ${ARCHITECTURE_FLAG}")

add_executable(ofa-example example.c)
target_compile_options(ofa-example PRIVATE ${ARCHITECTURE_FLAG})

# vim: ts=4 sw=4 sts=4 et
