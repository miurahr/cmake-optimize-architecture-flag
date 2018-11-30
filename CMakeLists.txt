

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

#------------------------------------------------------------------------------
# Example 1 For self compile
#
cmake_host_system_information_extra(RESULT MARCH QUERY MICRO_ARCHITECTURE)
message(STATUS "Detected micro architecture: ${MARCH}")
get_cpu_simd_features(fl "${MARCH}")
message(STATUS "Detected feature list: ${fl}")
cmake_compiler_machine_option(op ${MARCH})
message(STATUS "Add followings to compile options: ${op}")
# use ${op} for target_compile_option() value.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Example 2 for cross compile
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
#
# set values _name _flag _documentation
get_cpu_simd_features(simd_features ${TARGET_ARCHITECTURE})
set(SSE2 "sse2" "Use SSE2. If SSE2 instructions are not enabled the SSE implementation will be disabled.")
set(SSE3 "sse3" "Use SSE3. If SSE3 instructions are not enabled they will be emulated.")
set(SSSE3 "ssse3" "Use SSSE3. If SSSE3 instructions are not enabled they will be emulated.")
set(SSE4_1 "sse4.1" "Use SSE4.1. If SSE4.1 instructions are not enabled they will be emulated.")
set(SSE4_2 "sse4.2" "Use SSE4.2. If SSE4.2 instructions are not enabled they will be emulated.")
set(SSE4a "sse4a" "Use SSE4a. If SSE4a instructions are not enabled they will be emulated.")
set(AVX "avx" "Use AVX. This will all floating-point vector sizes relative to SSE.")
set(FMA "fma" "Use FMA.")
set(BMI2 "bmi2" "Use BMI2." )
set(AVX2 "avx2" "Use AVX2. This will double all of the vector sizes relative to SSE.")
set(XOP "xop" "Use XOP.")
set(FMA4 "fma4" "Use FMA4.")
set(AVX512F "avx512f" "Use AVX512F. This will double all floating-point vector sizes relative to AVX2.")
set(AVX512VL "avx512vl" "Use AVX512VL. This enables 128- and 256-bit vector length instructions with EVEX coding (improved write-masking & more vector registers).")
set(AVX512PF "avx512pf" "Use AVX512PF. This enables prefetch instructions for gathers and scatters." )
set(AVX512ER "avx512er" "Use AVX512ER. This enables exponential and reciprocal instructions." )
set(AVX512CD "avx512cd" "Use AVX512CD." )
set(AVX512DQ "avx512dq" "Use AVX512DQ." )
set(AVX512BW "avx512bw" "Use AVX512BW." )
set(AVX512IFMA "avx512ifma" "Use AVX512IFMA." )
set(AVX512VBMI "avx512vbmi" "Use AVX512VBMI." )
set(NEON "neon" "Use ARM NEON.")
#--------
foreach(target IN ITEMS SSE2 SSE3 SSSE3 SSE4_1 SSE4_2 SSE4a AVX FMA BMI2 AVX2 XOP FMA4
        AVX512F AVX512VL AVX512PF AVX512ER AVX512CD AVX512DQ AVX512BW AVX512IFMA AVX512VBMI NEON)
  set(_name ${target})
  list(GET ${target} 0 _flag)
  list(GET ${target} 1 _documentation)
  list(FIND simd_features "${_flag}" _found)
  if(_found GREATER -1)
    if(CMAKE_CXX_COMPILER_LOADED)
      check_cxx_compiler_flag("${_flag}" test_${_flag})
    elseif(CMAKE_C_COMPILER_LOADED)
      check_c_compiler_flag("${_flag}" test_${_flag})
    endif()
    if(test_${_flag})
      set(USE_${_name} TRUE CACHE BOOL "${documentation}")
      continue()
    endif()
  endif()
  set(USE_${_name} FALSE CACHE BOOL "${documentation}")
endforeach()

message(STATUS "Use compiler option: ${ARCHITECTURE_FLAG}")
add_executable(ofa-example example.c)
target_compile_options(ofa-example PRIVATE ${ARCHITECTURE_FLAG})

# vim: ts=2 sw=2 sts=2 et
