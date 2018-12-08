

#[=======================================================================[.rst:
OptimizeArchitectureFlags
-------------------------

  Example project to detect CPU feature set and return optimized flags

  Determine the host CPU feature set and determine the best set of compiler
  flags to enable all supported SIMD relevant features. Alternatively, the
  target CPU can be explicitly selected (for generating more generic binaries
  or for targeting a different system).

.. note::
  Compilers provide e.g. the -march=native flag to achieve a similar result.
  This fails to address the need for building for a different microarchitecture
  than the current host.
  The script tries to deduce all settings from the model and family numbers of
  the CPU instead of reading the CPUID flags from e.g. /proc/cpuinfo. This makes
  the detection more independent from the CPUID code in the kernel (e.g. avx2 is
  not listed on older kernels).

#]=======================================================================]

cmake_minimum_required (VERSION 3.5)

if(POLICY CMP0066)
    cmake_policy(SET CMP0066 NEW)
endif()

project(ofa-example VERSION 1.0 LANGUAGES C)
set(CMAKE_MODULE_PATH  ${CMAKE_CURRENT_SOURCE_DIR}/Modules)

include(CMakeHostSystemInformationExtra)
include(GetCPUSIMDFeatures)
include(CMakeCompilerMachineOption)

enable_testing()
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/Tests/arm")
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/Tests/x86_64")
set(TEST_BASE_DIR "${CMAKE_SOURCE_DIR}/Tests")
add_test(NAME cmake_host_system_information_extra_arm_test
         COMMAND ${CMAKE_COMMAND} -DCMAKE_MODULE_PATH=${TEST_BASE_DIR}/../Modules ${TEST_BASE_DIR}/arm/
         WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/Tests/arm")
add_test(NAME cmake_host_system_information_extra_x64_test
         COMMAND ${CMAKE_COMMAND} -DCMAKE_MODULE_PATH=${TEST_BASE_DIR}/../Modules ${TEST_BASE_DIR}/x86_64/
         WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/Tests/x86_64")

#------------------------------------------------------------------------------
# Example 1 For self compile
#
cmake_host_system_information_extra(RESULT MARCH QUERY PROCESSOR_MICRO_ARCHITECTURE)
message(STATUS "Detected micro architecture: ${MARCH}")
get_cpu_simd_features(fl "${MARCH}")
message(STATUS "Micro architecture ${MARCH} has features: ${fl}")
cmake_compiler_machine_option(op "${MARCH}")
message(STATUS "Compiler accept following options: ${op}")
# use ${op} for target_compile_option() value.
#------------------------------------------------------------------------------
# Example 2 check for some feature
#
cmake_host_system_information_extra(RESULT VAL QUERY HAS_AVX)
message(STATUS "Check host system has AVX feature: ${VAL}")

#------------------------------------------------------------------------------
# Example 3 for cross compile
#
# For cross compile, we should specify explicitly target platform,
# then compile optimized for target.
set(TARGET_ARCHITECTURE "knl" CACHE STRING "CPU architecture to optimize for. \
Using an incorrect setting here can result in crashes of the resulting binary because of invalid instructions used. \
Supported values: \"generic\", \"core\", \"merom\" (65nm Core2), \
\"penryn\" (45nm Core2), \"nehalem\", \"westmere\", \"sandy-bridge\", \"ivy-bridge\", \
\"haswell\", \"broadwell\", \"skylake\", \"skylake-xeon\", \"kaby-lake\", \"cannonlake\", \"silvermont\", \
\"goldmont\", \"knl\" (Knights Landing), \"atom\", \"k8\", \"k8-sse3\", \"barcelona\", \
\"istanbul\", \"magny-cours\", \"bulldozer\", \"interlagos\", \"piledriver\", \
\"amd-14h\", \"amd-16h\", \"zen\".")
cmake_compiler_machine_option(ARCHITECTURE_FLAG ${TARGET_ARCHITECTURE})

#
# Set USE_XXX cache variable for swich intrinsics in a source tree.
get_cpu_simd_features(simd_features ${TARGET_ARCHITECTURE})
foreach(target IN ITEMS SSE2 SSE3 SSSE3 SSE4_1 SSE4_2 SSE4a AVX FMA BMI2 AVX2 XOP FMA4
        AVX512F AVX512VL AVX512PF AVX512ER AVX512CD AVX512DQ AVX512BW AVX512IFMA AVX512VBMI NEON)
      string(TOLOWER ${target} _flag)
  list(FIND simd_features "${_flag}" _found)
  if(_found GREATER -1)
    if(MSVC)
      set(_flag "/arch:${target}")
    else()
      set(_flag "-m${_flag}")
    endif()
    if(CMAKE_CXX_COMPILER_LOADED)
      check_cxx_compiler_flag("${_flag}" test_${_name})
    elseif(CMAKE_C_COMPILER_LOADED)
      check_c_compiler_flag("${_flag}" test_${_name})
    endif()
    if(test_${_name})
      set(USE_${_name} TRUE CACHE BOOL "")
      continue()
    endif()
  endif()
  set(USE_${_name} FALSE CACHE BOOL "")
endforeach()

message(STATUS "Use compiler option: ${ARCHITECTURE_FLAG}")
add_executable(ofa-example example.c)
target_compile_options(ofa-example PRIVATE ${ARCHITECTURE_FLAG})

# vim: ts=2 sw=2 sts=2 et
