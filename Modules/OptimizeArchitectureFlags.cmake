# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:
OptimizeArchitectureFlags
-------------------------

  Detect CPU feature set and return optimized flags

.. command:: optimize_architecture_flag

   optimize_architecture_flags(<output variable name> [SSE_INTRINSICS_BROKEN]
                              [AVX_INTRINSICS_BROKEN] [AVX2_INTRINSICS_BROKEN])

  Determine the host CPU feature set and determine the best set of compiler
  flags to enable all supported SIMD relevant features. Alternatively, the
  target CPU can be explicitly selected (for generating more generic binaries
  or for targeting a different system).

.. note::
  If either of SSE_INTRINSICS_BROKEN, AVX_INTRINSICS_BROKEN and AVX2_INTRINSICS_BROKEN
  is defined and set, the optimize_architecture_flags
  function will consequently disable the relevant features via compiler flags.

.. note::
  Compilers provide e.g. the -march=native flag to achieve a similar result.
  This fails to address the need for building for a different microarchitecture
  than the current host.
  The script tries to deduce all settings from the model and family numbers of
  the CPU instead of reading the CPUID flags from e.g. /proc/cpuinfo. This makes
  the detection more independent from the CPUID code in the kernel (e.g. avx2 is
  not listed on older kernels).

.. note::
  Optimize_architecture_flags function defines two utility macro utilized inside
  function to reduce code size: __check_compiler_flag()
#]=======================================================================]

cmake_policy(PUSH)
if(POLICY CMP0066)
    cmake_policy(SET CMP0066 NEW)
endif()

include("${CMAKE_CURRENT_LIST_DIR}/DetectCPUMicroArchitecture.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/GetMarchCompilerOptions.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/GetCPUSIMDFeatures.cmake")

function(OPTIMIZE_ARCHITECTURE_FLAGS _outvar)
    set(_options SSE_INTRINSICS_BROKEN  AVX_INTRINSICS_BROKEN AVX2_INTRINSICS_BROKEN)
    set(_oneValueArgs TARGET_ARCHITECTURE)
    set(_multiValueArgs)
    cmake_parse_arguments(OFA "${_options}" "${_oneValueArgs}" "${_multiValueArgs}" ${ARGN})

    if(OFA_TARGET_ARCHITECTURE STREQUAL "auto")
        detect_cpu_micro_architecture(TARCH)
    else()
        set(TARCH ${OFA_TARGET_ARCHITECTURE})
    endif()
    set(ARCHITECTURE_FLAGS)
    get_march_compiler_options(ARCHITECTURE_FLAGS ${TARCH})
    get_cpu_simd_features(_available_vector_units_list ${TARCH})

    if(DEFINED OFA_AVX_INTRINSICS_BROKEN AND OFA_AVX_INTRINSICS_BROKEN)
        message(STATUS "AVX disabled because of old/broken toolchain")
        set(_avx_broken true)
        set(_avx2_broken true)
        set(_fma4_broken true)
        set(_xop_broken true)
    else()
        set(_avx_broken false)
        if(DEFINED OFA_FMA4_INTRINSICS_BROKEN AND OFA_FMA4_INTRINSICS_BROKEN)
            message(STATUS "FMA4 disabled because of old/broken toolchain")
            set(_fma4_broken true)
        else()
            set(_fma4_broken false)
        endif()
        if(DEFINED OFA_XOP_INTRINSICS_BROKEN AND OFA_XOP_INTRINSICS_BROKEN)
            message(STATUS "XOP disabled because of old/broken toolchain")
            set(_xop_broken true)
        else()
            set(_xop_broken false)
        endif()
        if(DEFINED OFA_AVX2_INTRINSICS_BROKEN AND OFA_AVX2_INTRINSICS_BROKEN)
            message(STATUS "AVX2 disabled because of old/broken toolchain")
            set(_avx2_broken true)
        else()
            set(_avx2_broken false)
        endif()
    endif()

    #set values _name _flag _documentation _broken
    set(SSE2 "sse2" "Use SSE2. If SSE2 instructions are not enabled the SSE implementation will be disabled." false)
    set(SSE3 "sse3" "Use SSE3. If SSE3 instructions are not enabled they will be emulated." false)
    set(SSSE3 "ssse3" "Use SSSE3. If SSSE3 instructions are not enabled they will be emulated." false)
    set(SSE4_1 "sse4.1" "Use SSE4.1. If SSE4.1 instructions are not enabled they will be emulated." false)
    set(SSE4_2 "sse4.2" "Use SSE4.2. If SSE4.2 instructions are not enabled they will be emulated." false)
    set(SSE4a "sse4a" "Use SSE4a. If SSE4a instructions are not enabled they will be emulated." false)
    set(AVX "avx" "Use AVX. This will all floating-point vector sizes relative to SSE." ${_avx_broken})
    set(FMA "fma" "Use FMA." ${_avx_broken})
    set(BMI2 "bmi2" "Use BMI2." ${_avx_broken})
    set(AVX2 "avx2" "Use AVX2. This will double all of the vector sizes relative to SSE." ${_avx2_broken})
    set(XOP "xop" "Use XOP." ${_xop_broken})
    set(FMA4 "fma4" "Use FMA4." ${_fma4_broken})
    set(AVX512F "avx512f" "Use AVX512F. This will double all floating-point vector sizes relative to AVX2." false)
    set(AVX512VL "avx512vl" "Use AVX512VL. This enables 128- and 256-bit vector length instructions with EVEX coding (improved write-masking & more vector registers)." ${_avx2_broken})
    set(AVX512PF "avx512pf" "Use AVX512PF. This enables prefetch instructions for gathers and scatters." false)
    set(AVX512ER "avx512er" "Use AVX512ER. This enables exponential and reciprocal instructions." false)
    set(AVX512CD "avx512cd" "Use AVX512CD." false)
    set(AVX512DQ "avx512dq" "Use AVX512DQ." false)
    set(AVX512BW "avx512bw" "Use AVX512BW." false)
    set(AVX512IFMA "avx512ifma" "Use AVX512IFMA." false)
    set(AVX512VBMI "avx512vbmi" "Use AVX512VBMI." false)
    foreach(target IN ITEMS SSE2 SSE3 SSSE3 SSE4_1 SSE4_2 SSE4a AVX FMA BMI2 AVX2 XOP FMA4
            AVX512F AVX512VL AVX512PF AVX512ER AVX512CD AVX512DQ AVX512BW AVX512IFMA AVX512VBMI)
        set(_name ${target})
        list(GET ${target} 0 _flag)
        list(GET ${target} 1 _documentation)
        list(GET ${target} 2 _broken)
        list(FIND _available_vector_units_list "${_flag}" _found)
        if(_broken OR (_found LESS 0))
            set(USE_${_name} FALSE CACHE INTERNAL "${documentation}")
        else()
            set(USE_${_name} TRUE CACHE INTERNAL "${documentation}")
        endif()
    endforeach()

    set(${_outvar} ${ARCHITECTURE_FLAGS} PARENT_SCOPE)
endfunction()

cmake_policy(POP)
