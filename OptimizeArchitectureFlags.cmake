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
  function to reduce code size:
   _OFA_enable_or_disable() and _OFA_add_compiler_flag()

#]=======================================================================]


include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)
include(CheckIncludeFileCXX)
include(CheckIncludeFile)

if(POLICY CMP0066)
    cmake_policy(SET CMP0066 NEW)
endif()

function(OPTIMIZE_ARCHITECTURE_FLAGS _outvar)
    set(OFA_FUNCNAME "optimize_architecture_flag()")
    # - Add a given compiler flag to flags variables.
    # _OFA_add_compiler_flag(<flag> [C_FLAGS <var>] [CXX_FLAGS <var>] [C_RESULT <var>]
    #                        [CXX_RESULT <var>])
    macro(_OFA_add_compiler_flag _flag)
        string(REGEX REPLACE "[-.+/:= ;]" "_" _flag_esc "${_flag}")
        set(_c_flags "CMAKE_C_FLAGS")
        set(_cxx_flags "CMAKE_CXX_FLAGS")
        set(_c_result tmp)
        set(_cxx_result tmp)
        if(${ARGC} EQUAL 2)
            message(WARNING "Deprecated use of the _OFA_add_compiler_flag macro.")
            unset(_c_result)
            set(_cxx_result ${ARGV1})
        elseif(${ARGC} GREATER 2)
            set(state 0)
            unset(_c_flags)
            unset(_cxx_flags)
            unset(_c_result)
            unset(_cxx_result)
            foreach(_arg ${ARGN})
                if("x${_arg}" STREQUAL "xC_FLAGS")
                    set(state 1)
                    if(NOT DEFINED _c_result)
                        set(_c_result tmp0)
                    endif()
                elseif("x${_arg}" STREQUAL "xCXX_FLAGS")
                    set(state 2)
                    if(NOT DEFINED _cxx_result)
                        set(_cxx_result tmp1)
                    endif()
                elseif("x${_arg}" STREQUAL "xC_RESULT")
                    set(state 3)
                elseif("x${_arg}" STREQUAL "xCXX_RESULT")
                    set(state 4)
                elseif(state EQUAL 1)
                    set(_c_flags "${_arg}")
                elseif(state EQUAL 2)
                    set(_cxx_flags "${_arg}")
                elseif(state EQUAL 3)
                    set(_c_result "${_arg}")
                elseif(state EQUAL 4)
                    set(_cxx_result "${_arg}")
                else()
                    message(FATAL_ERROR "Syntax error for _OFA_add_compiler_flag")
                endif()
            endforeach()
        endif()

        set(_c_code "int main() { return 0; }")
        set(_cxx_code "int main() { return 0; }")
        if("${_flag}" STREQUAL "-mfma")
            # Compiling with FMA3 support may fail only at the assembler level.
            # In that case we need to have such an instruction in the test code
            set(_c_code "#include <immintrin.h>
      __m128 foo(__m128 x) { return _mm_fmadd_ps(x, x, x); }
      int main() { return 0; }")
            set(_cxx_code "${_c_code}")
        elseif("${_flag}" STREQUAL "-std=c++14" OR "${_flag}" STREQUAL "-std=c++1y")
            set(_cxx_code "#include <utility>
      struct A { friend auto f(); };
      template <int N> constexpr int var_temp = N;
      template <std::size_t... I> void foo(std::index_sequence<I...>) {}
      int main() { foo(std::make_index_sequence<4>()); return 0; }")
        elseif("${_flag}" STREQUAL "-std=c++17" OR "${_flag}" STREQUAL "-std=c++1z")
            set(_cxx_code "#include <functional>
      int main() { return 0; }")
        elseif("${_flag}" STREQUAL "-stdlib=libc++")
            # Compiling with libc++ not only requires a compiler that understands it, but also
            # the libc++ headers itself
            set(_cxx_code "#include <iostream>
      #include <cstdio>
      int main() { return 0; }")
        elseif("${_flag}" STREQUAL "-march=knl"
               OR "${_flag}" STREQUAL "-march=skylake-avx512"
               OR "${_flag}" STREQUAL "/arch:AVX512"
               OR "${_flag}" STREQUAL "/arch:KNL"
               OR "${_flag}" MATCHES "^-mavx512.")
            # Make sure the intrinsics are there
            set(_cxx_code "#include <immintrin.h>
      __m512 foo(__m256 v) {
        return _mm512_castpd_ps(_mm512_insertf64x4(_mm512_setzero_pd(), _mm256_castps_pd(v), 0x0));
      }
      __m512i bar() { return _mm512_setzero_si512(); }
      int main() { return 0; }")
        elseif("${_flag}" STREQUAL "-mno-sse" OR "${_flag}" STREQUAL "-mno-sse2")
            set(_cxx_code "#include <cstdio>
      #include <cstdlib>
      int main() { return std::atof(\"0\"); }")
        else()
            set(_cxx_code "#include <cstdio>
      int main() { return 0; }")
        endif()

        if(DEFINED _c_result)
            check_c_compiler_flag("${_flag}" check_c_compiler_flag_${_flag_esc} "${_c_code}")
            set(${_c_result} ${check_c_compiler_flag_${_flag_esc}})
        endif()
        if(DEFINED _cxx_result)
            check_cxx_compiler_flag("${_flag}" check_cxx_compiler_flag_${_flag_esc} "${_cxx_code}")
            set(${_cxx_result} ${check_cxx_compiler_flag_${_flag_esc}})
        endif()

        if(check_c_compiler_flag_${_flag_esc} AND DEFINED _c_flags)
            list(APPEND ${_c_flags} "${_flag}")
        endif()
        if(check_cxx_compiler_flag_${_flag_esc} AND DEFINED _cxx_flags)
            list(APPEND ${_cxx_flags} "${_flag}")
        endif()
    endmacro(_OFA_add_compiler_flag)

    set(ARCHITECTURE_FLAGS)
    if("${CMAKE_SYSTEM_PROCESSOR}" MATCHES "(x86|AMD64)")
        set(TARGET_ARCHITECTURE "auto" CACHE STRING "CPU architecture to optimize for. \
Using an incorrect setting here can result in crashes of the resulting binary because of invalid instructions used. \
Setting the value to \"auto\" will try to optimize for the architecture where cmake is called. \
Other supported values are: \"none\", \"generic\", \"core\", \"merom\" (65nm Core2), \
\"penryn\" (45nm Core2), \"nehalem\", \"westmere\", \"sandy-bridge\", \"ivy-bridge\", \
\"haswell\", \"broadwell\", \"skylake\", \"skylake-xeon\", \"kaby-lake\", \"cannonlake\", \"silvermont\", \
\"goldmont\", \"knl\" (Knights Landing), \"atom\", \"k8\", \"k8-sse3\", \"barcelona\", \
\"istanbul\", \"magny-cours\", \"bulldozer\", \"interlagos\", \"piledriver\", \
\"AMD 14h\", \"AMD 16h\", \"zen\".")

        set(_force)
        if(NOT _last_target_arch STREQUAL "")
            if(NOT _last_target_arch STREQUAL "${TARGET_ARCHITECTURE}")
                message(STATUS "${OFA_FUNCNAME}: target changed from \"${_last_target_arch}\" to \"${TARGET_ARCHITECTURE}\"")
                set(_force FORCE)
            endif()
        endif()

        set(_last_target_arch "${TARGET_ARCHITECTURE}" CACHE STRING "" FORCE)
        mark_as_advanced(_last_target_arch)
        string(TOLOWER "${TARGET_ARCHITECTURE}" TARGET_ARCHITECTURE)

        set(_vendor_id)
        set(_cpu_family)
        set(_cpu_model)
        if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
            file(READ "/proc/cpuinfo" _cpuinfo)
            string(REGEX REPLACE ".*vendor_id[ \t]*:[ \t]+([a-zA-Z0-9_-]+).*" "\\1" _vendor_id "${_cpuinfo}")
            string(REGEX REPLACE ".*cpu family[ \t]*:[ \t]+([a-zA-Z0-9_-]+).*" "\\1" _cpu_family "${_cpuinfo}")
            string(REGEX REPLACE ".*model[ \t]*:[ \t]+([a-zA-Z0-9_-]+).*" "\\1" _cpu_model "${_cpuinfo}")
            string(REGEX REPLACE ".*flags[ \t]*:[ \t]+([^\n]+).*" "\\1" _cpu_flags "${_cpuinfo}")
        elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
            exec_program("/usr/sbin/sysctl -n machdep.cpu.vendor machdep.cpu.model machdep.cpu.family machdep.cpu.features" OUTPUT_VARIABLE _sysctl_output_string)
            string(REPLACE "\n" ";" _sysctl_output ${_sysctl_output_string})
            list(GET _sysctl_output 0 _vendor_id)
            list(GET _sysctl_output 1 _cpu_model)
            list(GET _sysctl_output 2 _cpu_family)
            list(GET _sysctl_output 3 _cpu_flags)

            string(TOLOWER "${_cpu_flags}" _cpu_flags)
            string(REPLACE "." "_" _cpu_flags "${_cpu_flags}")
        elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
            get_filename_component(_vendor_id "[HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\CentralProcessor\\0;VendorIdentifier]" NAME CACHE)
            get_filename_component(_cpu_id "[HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\CentralProcessor\\0;Identifier]" NAME CACHE)
            string(REGEX REPLACE ".* Family ([0-9]+) .*" "\\1" _cpu_family "${_cpu_id}")
            string(REGEX REPLACE ".* Model ([0-9]+) .*" "\\1" _cpu_model "${_cpu_id}")
        endif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        if(_vendor_id STREQUAL "GenuineIntel")
            if(_cpu_family EQUAL 6)
                # taken from the Intel ORM
                # http://www.intel.com/content/www/us/en/processors/architectures-software-developer-manuals.html
                # CPUID Signature Values of Of Recent Intel Microarchitectures
                # 4E 5E       | Skylake microarchitecture
                # 3D 47 56    | Broadwell microarchitecture
                # 3C 45 46 3F | Haswell microarchitecture
                # 3A 3E       | Ivy Bridge microarchitecture
                # 2A 2D       | Sandy Bridge microarchitecture
                # 25 2C 2F    | Intel microarchitecture Westmere
                # 1A 1E 1F 2E | Intel microarchitecture Nehalem
                # 17 1D       | Enhanced Intel Core microarchitecture
                # 0F          | Intel Core microarchitecture
                #
                # Intel SDM Vol. 3C 35-1 / December 2016:
                # 57          | Xeon Phi 3200, 5200, 7200  [Knights Landing]
                # 85          | Future Xeon Phi
                # 8E 9E       | 7th gen. Core              [Kaby Lake]
                # 55          | Future Xeon                [Skylake w/ AVX512]
                # 4E 5E       | 6th gen. Core / E3 v5      [Skylake w/o AVX512]
                # 56          | Xeon D-1500                [Broadwell]
                # 4F          | Xeon E5 v4, E7 v4, i7-69xx [Broadwell]
                # 47          | 5th gen. Core / Xeon E3 v4 [Broadwell]
                # 3D          | M-5xxx / 5th gen.          [Broadwell]
                # 3F          | Xeon E5 v3, E7 v3, i7-59xx [Haswell-E]
                # 3C 45 46    | 4th gen. Core, Xeon E3 v3  [Haswell]
                # 3E          | Xeon E5 v2, E7 v2, i7-49xx [Ivy Bridge-E]
                # 3A          | 3rd gen. Core, Xeon E3 v2  [Ivy Bridge]
                # 2D          | Xeon E5, i7-39xx           [Sandy Bridge]
                # 2F          | Xeon E7
                # 2A          | Xeon E3, 2nd gen. Core     [Sandy Bridge]
                # 2E          | Xeon 7500, 6500 series
                # 25 2C       | Xeon 3600, 5600 series, Core i7, i5 and i3
                #
                # Values from the Intel SDE:
                # 5C | Goldmont
                # 5A | Silvermont
                # 57 | Knights Landing
                # 66 | Cannonlake
                # 55 | Skylake Server
                # 4E | Skylake Client
                # 3C | Broadwell (likely a bug in the SDE)
                # 3C | Haswell

                if(_cpu_model LESS 14)
                    message(WARNING "${OFA_FUNCNAME}:Your CPU (family ${_cpu_family}, model ${_cpu_model}) is not known. Auto-detection of optimization flags failed and will use the generic CPU settings with SSE2.")
                    set(TARGET_ARCHITECTURE "generic")
                else()
                    set(architecture_lookup_hash
                        87  "knl"
                        92  "goldmont"
                        90  "silvermont"    76 "silvermont"
                        102 "cannonlake"
                        142 "kaby-lake"    158 "kaby-lake"
                        85  "skylake-avx512"
                        78  "skylake"       94  "skylake"
                        61  "broadwell"     71  "broadwell" 79  "broadwell" 86  "broadwell"
                        60  "haswell"       69  "haswell"   70  "haswell"   63  "haswell"
                        58  "ivy-bridge"    62  "ivy-bridge"
                        42  "sandy-bridge"  45  "sandy-bridge"
                        31  "westmere"      37  "westmere"  44  "westmere"  47  "westmere"
                        26  "nehalem"       30  "nehalem"   31  "nehalem"   46  "nehalem"
                        23  "penryn"        29  "penryn"
                        15  "merom"
                        28  "atom"
                        14  "core"
                    )
                    # here lookup hash key and return value as TARGET_ARCHITECTURE
                    list(FIND architecture_lookup_hash "${_cpu_model}" _found)
                    if(_found GREATER -1)
                        math(EXPR index "${_found}+1")
                        list(GET architecture_lookup_hash ${index} TARGET_ARCHITECTURE)
                    else()
                        message(WARNING "${OFA_FUNCNAME}:Your CPU (family ${_cpu_family}, model ${_cpu_model}) is not known. Auto-detection of optimization flags failed and will use the 65nm Core 2 CPU settings.")
                        set(TARGET_ARCHITECTURE "merom")
                    endif()
                endif()
            elseif(_cpu_family EQUAL 7) # Itanium (not supported)
                message(WARNING "${OFA_FUNCNAME}:Your CPU (Itanium: family ${_cpu_family}, model ${_cpu_model}) is not supported by OptimizeForArchitecture.cmake.")
            elseif(_cpu_family EQUAL 15) # NetBurst
                list(APPEND _available_vector_units_list "sse" "sse2")
                if(_cpu_model GREATER 2) # Not sure whether this must be 3 or even 4 instead
                    list(APPEND _available_vector_units_list "sse" "sse2" "sse3")
                endif(_cpu_model GREATER 2)
            endif(_cpu_family EQUAL 6)
        elseif(_vendor_id STREQUAL "AuthenticAMD")
             if(_cpu_family EQUAL 23)
                set(TARGET_ARCHITECTURE "zen")
            elseif(_cpu_family EQUAL 22) # 16h
                set(TARGET_ARCHITECTURE "AMD 16h")
            elseif(_cpu_family EQUAL 21) # 15h
                if(_cpu_model LESS 2)
                    set(TARGET_ARCHITECTURE "bulldozer")
                else()
                    set(TARGET_ARCHITECTURE "piledriver")
                endif()
            elseif(_cpu_family EQUAL 20) # 14h
                set(TARGET_ARCHITECTURE "AMD 14h")
            elseif(_cpu_family EQUAL 18) # 12h
            elseif(_cpu_family EQUAL 16) # 10h
                set(TARGET_ARCHITECTURE "barcelona")
            elseif(_cpu_family EQUAL 15)
                set(TARGET_ARCHITECTURE "k8")
                if(_cpu_model GREATER 64) # I don't know the right number to put here. This is just a guess from the hardware I have access to
                    set(TARGET_ARCHITECTURE "k8-sse3")
                endif(_cpu_model GREATER 64)
            endif()
        endif(_vendor_id STREQUAL "GenuineIntel")

        set(_march_flag_list)
        set(_available_vector_units_list)
        if(TARGET_ARCHITECTURE STREQUAL "core")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3")
        elseif(TARGET_ARCHITECTURE STREQUAL "merom")
            list(APPEND _march_flag_list "merom")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3")
        elseif(TARGET_ARCHITECTURE STREQUAL "penryn")
            list(APPEND _march_flag_list "penryn")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3")
            message(STATUS "Sadly the Penryn architecture exists in variants with SSE4.1 and without SSE4.1.")
            if(_cpu_flags MATCHES "sse4_1")
                message(STATUS "SSE4.1: enabled (auto-detected from this computer's CPU flags)")
                list(APPEND _available_vector_units_list "sse4.1")
            else()
                message(STATUS "SSE4.1: disabled (auto-detected from this computer's CPU flags)")
            endif()
        elseif(TARGET_ARCHITECTURE STREQUAL "knl")
            list(APPEND _march_flag_list "knl")
            list(APPEND _march_flag_list "broadwell")
            list(APPEND _march_flag_list "haswell")
            list(APPEND _march_flag_list "core-avx2")
            list(APPEND _march_flag_list "ivybridge")
            list(APPEND _march_flag_list "core-avx-i")
            list(APPEND _march_flag_list "sandybridge")
            list(APPEND _march_flag_list "corei7-avx")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2" "avx")
            list(APPEND _available_vector_units_list "rdrnd" "f16c")
            list(APPEND _available_vector_units_list "avx2" "fma" "bmi" "bmi2")
            list(APPEND _available_vector_units_list "avx512f" "avx512pf" "avx512er" "avx512cd")
        elseif(TARGET_ARCHITECTURE STREQUAL "cannonlake")
            list(APPEND _march_flag_list "cannonlake")
            list(APPEND _march_flag_list "skylake-avx512")
            list(APPEND _march_flag_list "skylake")
            list(APPEND _march_flag_list "broadwell")
            list(APPEND _march_flag_list "haswell")
            list(APPEND _march_flag_list "core-avx2")
            list(APPEND _march_flag_list "ivybridge")
            list(APPEND _march_flag_list "core-avx-i")
            list(APPEND _march_flag_list "sandybridge")
            list(APPEND _march_flag_list "corei7-avx")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2" "avx")
            list(APPEND _available_vector_units_list "rdrnd" "f16c")
            list(APPEND _available_vector_units_list "avx2" "fma" "bmi" "bmi2")
            list(APPEND _available_vector_units_list "avx512f" "avx512cd" "avx512dq" "avx512bw" "avx512vl")
            list(APPEND _available_vector_units_list "avx512ifma" "avx512vbmi")
        elseif(TARGET_ARCHITECTURE STREQUAL "kaby-lake")
            list(APPEND _march_flag_list "skylake")
            list(APPEND _march_flag_list "broadwell")
            list(APPEND _march_flag_list "haswell")
            list(APPEND _march_flag_list "core-avx2")
            list(APPEND _march_flag_list "ivybridge")
            list(APPEND _march_flag_list "core-avx-i")
            list(APPEND _march_flag_list "sandybridge")
            list(APPEND _march_flag_list "corei7-avx")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2" "avx")
            list(APPEND _available_vector_units_list "rdrnd" "f16c")
            list(APPEND _available_vector_units_list "avx2" "fma" "bmi" "bmi2")
        elseif(TARGET_ARCHITECTURE STREQUAL "skylake-xeon" OR TARGET_ARCHITECTURE STREQUAL "skylake-avx512")
            list(APPEND _march_flag_list "skylake-avx512")
            list(APPEND _march_flag_list "skylake")
            list(APPEND _march_flag_list "broadwell")
            list(APPEND _march_flag_list "haswell")
            list(APPEND _march_flag_list "core-avx2")
            list(APPEND _march_flag_list "ivybridge")
            list(APPEND _march_flag_list "core-avx-i")
            list(APPEND _march_flag_list "sandybridge")
            list(APPEND _march_flag_list "corei7-avx")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2" "avx")
            list(APPEND _available_vector_units_list "rdrnd" "f16c")
            list(APPEND _available_vector_units_list "avx2" "fma" "bmi" "bmi2")
            list(APPEND _available_vector_units_list "avx512f" "avx512cd" "avx512dq" "avx512bw" "avx512vl")
        elseif(TARGET_ARCHITECTURE STREQUAL "skylake")
            list(APPEND _march_flag_list "skylake")
            list(APPEND _march_flag_list "broadwell")
            list(APPEND _march_flag_list "haswell")
            list(APPEND _march_flag_list "core-avx2")
            list(APPEND _march_flag_list "ivybridge")
            list(APPEND _march_flag_list "core-avx-i")
            list(APPEND _march_flag_list "sandybridge")
            list(APPEND _march_flag_list "corei7-avx")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2" "avx")
            list(APPEND _available_vector_units_list "rdrnd" "f16c")
            list(APPEND _available_vector_units_list "avx2" "fma" "bmi" "bmi2")
        elseif(TARGET_ARCHITECTURE STREQUAL "broadwell")
            list(APPEND _march_flag_list "broadwell")
            list(APPEND _march_flag_list "haswell")
            list(APPEND _march_flag_list "core-avx2")
            list(APPEND _march_flag_list "ivybridge")
            list(APPEND _march_flag_list "core-avx-i")
            list(APPEND _march_flag_list "sandybridge")
            list(APPEND _march_flag_list "corei7-avx")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2" "avx")
            list(APPEND _available_vector_units_list "rdrnd" "f16c")
            list(APPEND _available_vector_units_list "avx2" "fma" "bmi" "bmi2")
        elseif(TARGET_ARCHITECTURE STREQUAL "haswell")
            list(APPEND _march_flag_list "haswell")
            list(APPEND _march_flag_list "ivybridge")
            list(APPEND _march_flag_list "sandybridge")
            list(APPEND _march_flag_list "core-avx-i")
            list(APPEND _march_flag_list "core-avx2")
            list(APPEND _march_flag_list "corei7-avx")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2" "avx")
            list(APPEND _available_vector_units_list "rdrnd" "f16c")
            list(APPEND _available_vector_units_list "avx2" "fma" "bmi" "bmi2")
        elseif(TARGET_ARCHITECTURE STREQUAL "ivy-bridge")
            list(APPEND _march_flag_list "ivybridge")
            list(APPEND _march_flag_list "sandybridge")
            list(APPEND _march_flag_list "corei7-avx")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2" "avx" "avxi" "rdrnd" "f16c")
        elseif(TARGET_ARCHITECTURE STREQUAL "sandy-bridge")
            list(APPEND _march_flag_list "sandybridge")
            list(APPEND _march_flag_list "corei7-avx")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2" "avx")
        elseif(TARGET_ARCHITECTURE STREQUAL "westmere")
            list(APPEND _march_flag_list "westmere")
            list(APPEND _march_flag_list "nehalem")
            list(APPEND _march_flag_list "corei7")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2")
        elseif(TARGET_ARCHITECTURE STREQUAL "nehalem")
            list(APPEND _march_flag_list "nehalem")
            list(APPEND _march_flag_list "corei7")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2")
        elseif(TARGET_ARCHITECTURE STREQUAL "goldmont")
            list(APPEND _march_flag_list "goldmont")
            list(APPEND _march_flag_list "silvermont")
            list(APPEND _march_flag_list "westmere")
            list(APPEND _march_flag_list "corei7")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2")
            list(APPEND _available_vector_units_list "rdrnd")
        elseif(TARGET_ARCHITECTURE STREQUAL "silvermont")
            list(APPEND _march_flag_list "silvermont")
            list(APPEND _march_flag_list "westmere")
            list(APPEND _march_flag_list "corei7")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2")
            list(APPEND _available_vector_units_list "rdrnd")
        elseif(TARGET_ARCHITECTURE STREQUAL "atom")
            list(APPEND _march_flag_list "atom")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3")
        elseif(TARGET_ARCHITECTURE STREQUAL "k8")
            list(APPEND _march_flag_list "k8")
            list(APPEND _available_vector_units_list "sse" "sse2")
        elseif(TARGET_ARCHITECTURE STREQUAL "k8-sse3")
            list(APPEND _march_flag_list "k8-sse3")
            list(APPEND _march_flag_list "k8")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3")
        elseif(TARGET_ARCHITECTURE STREQUAL "AMD 16h")
            list(APPEND _march_flag_list "btver2")
            list(APPEND _march_flag_list "btver1")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4a" "sse4.1" "sse4.2" "avx" "f16c")
        elseif(TARGET_ARCHITECTURE STREQUAL "AMD 14h")
            list(APPEND _march_flag_list "btver1")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4a")
        elseif(TARGET_ARCHITECTURE STREQUAL "zen")
            list(APPEND _march_flag_list "znver1")
            list(APPEND _march_flag_list "skylake")
            list(APPEND _march_flag_list "broadwell")
            list(APPEND _march_flag_list "haswell")
            list(APPEND _march_flag_list "core-avx2")
            list(APPEND _march_flag_list "ivybridge")
            list(APPEND _march_flag_list "core-avx-i")
            list(APPEND _march_flag_list "sandybridge")
            list(APPEND _march_flag_list "corei7-avx")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2" "avx")
            list(APPEND _available_vector_units_list "rdrnd" "f16c")
            list(APPEND _available_vector_units_list "avx2" "fma" "bmi" "bmi2")
            list(APPEND _available_vector_units_list "sse4a")
        elseif(TARGET_ARCHITECTURE STREQUAL "piledriver")
            list(APPEND _march_flag_list "bdver2")
            list(APPEND _march_flag_list "bdver1")
            list(APPEND _march_flag_list "bulldozer")
            list(APPEND _march_flag_list "barcelona")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4a" "sse4.1" "sse4.2" "avx" "xop" "fma4" "fma" "f16c")
        elseif(TARGET_ARCHITECTURE STREQUAL "interlagos")
            list(APPEND _march_flag_list "bdver1")
            list(APPEND _march_flag_list "bulldozer")
            list(APPEND _march_flag_list "barcelona")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4a" "sse4.1" "sse4.2" "avx" "xop" "fma4")
        elseif(TARGET_ARCHITECTURE STREQUAL "bulldozer")
            list(APPEND _march_flag_list "bdver1")
            list(APPEND _march_flag_list "bulldozer")
            list(APPEND _march_flag_list "barcelona")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4a" "sse4.1" "sse4.2" "avx" "xop" "fma4")
        elseif(TARGET_ARCHITECTURE STREQUAL "barcelona")
            list(APPEND _march_flag_list "barcelona")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "sse4a")
        elseif(TARGET_ARCHITECTURE STREQUAL "istanbul")
            list(APPEND _march_flag_list "barcelona")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "sse4a")
        elseif(TARGET_ARCHITECTURE STREQUAL "magny-cours")
            list(APPEND _march_flag_list "barcelona")
            list(APPEND _march_flag_list "core2")
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "sse4a")
        elseif(TARGET_ARCHITECTURE STREQUAL "generic")
            list(APPEND _march_flag_list "generic")
        elseif(TARGET_ARCHITECTURE STREQUAL "none")
            # add this clause to remove it from the else clause
        else(TARGET_ARCHITECTURE STREQUAL "core")
            message(FATAL_ERROR "Unknown target architecture: \"${TARGET_ARCHITECTURE}\". Please set TARGET_ARCHITECTURE to a supported value.")
        endif(TARGET_ARCHITECTURE STREQUAL "core")

        if(TARGET_ARCHITECTURE STREQUAL "none")
            message(WARNING "Unsupported target architecture. No flag is added.")
        else()
            set(_disable_vector_unit_list)
            set(_enable_vector_unit_list)
            if(DEFINED CMAKE_AVX_INTRINSICS_BROKEN AND CMAKE_AVX_INTRINSICS_BROKEN)
                message(STATUS "AVX disabled because of old/broken toolchain")
                set(_avx_broken true)
                set(_avx2_broken true)
                set(_fma4_broken true)
                set(_xop_broken true)
            else()
                set(_avx_broken false)
                if(DEFINED CMAKE_FMA4_INTRINSICS_BROKEN AND CMAKE_FMA4_INTRINSICS_BROKEN)
                    message(STATUS "FMA4 disabled because of old/broken toolchain")
                    set(_fma4_broken true)
                else()
                    set(_fma4_broken false)
                endif()
                if(DEFINED CMAKE_XOP_INTRINSICS_BROKEN AND CMAKE_XOP_INTRINSICS_BROKEN)
                    message(STATUS "XOP disabled because of old/broken toolchain")
                    set(_xop_broken true)
                else()
                    set(_xop_broken false)
                endif()
                if(DEFINED CMAKE_AVX2_INTRINSICS_BROKEN AND CMAKE_AVX2_INTRINSICS_BROKEN)
                    message(STATUS "AVX2 disabled because of old/broken toolchain")
                    set(_avx2_broken true)
                else()
                    set(_avx2_broken false)
                endif()
            endif()

            macro(_OFA_enable_or_disable _name _flag _documentation _broken)
                list(FIND _available_vector_units_list "${_flag}" _found)
                if(_broken OR (_found EQUAL -1))
                    set(USE_${_name} FALSE CACHE BOOL "${documentation}" ${_force})
                else()
                    set(USE_${_name} TRUE CACHE BOOL "${documentation}" ${_force})
                endif()
                mark_as_advanced(USE_${_name})
                if(USE_${_name})
                    list(APPEND _enable_vector_unit_list "${_flag}")
                else()
                    list(APPEND _disable_vector_unit_list "${_flag}")
                endif()
            endmacro()
            _OFA_enable_or_disable(SSE2 "sse2" "Use SSE2. If SSE2 instructions are not enabled the SSE implementation will be disabled." false)
            _OFA_enable_or_disable(SSE3 "sse3" "Use SSE3. If SSE3 instructions are not enabled they will be emulated." false)
            _OFA_enable_or_disable(SSSE3 "ssse3" "Use SSSE3. If SSSE3 instructions are not enabled they will be emulated." false)
            _OFA_enable_or_disable(SSE4_1 "sse4.1" "Use SSE4.1. If SSE4.1 instructions are not enabled they will be emulated." false)
            _OFA_enable_or_disable(SSE4_2 "sse4.2" "Use SSE4.2. If SSE4.2 instructions are not enabled they will be emulated." false)
            _OFA_enable_or_disable(SSE4a "sse4a" "Use SSE4a. If SSE4a instructions are not enabled they will be emulated." false)
            _OFA_enable_or_disable(AVX "avx" "Use AVX. This will all floating-point vector sizes relative to SSE." _avx_broken)
            _OFA_enable_or_disable(FMA "fma" "Use FMA." _avx_broken)
            _OFA_enable_or_disable(BMI2 "bmi2" "Use BMI2." _avx_broken)
            _OFA_enable_or_disable(AVX2 "avx2" "Use AVX2. This will double all of the vector sizes relative to SSE." _avx2_broken)
            _OFA_enable_or_disable(XOP "xop" "Use XOP." _xop_broken)
            _OFA_enable_or_disable(FMA4 "fma4" "Use FMA4." _fma4_broken)
            _OFA_enable_or_disable(AVX512F "avx512f" "Use AVX512F. This will double all floating-point vector sizes relative to AVX2." false)
            _OFA_enable_or_disable(AVX512VL "avx512vl" "Use AVX512VL. This enables 128- and 256-bit vector length instructions with EVEX coding (improved write-masking & more vector registers)." _avx2_broken)
            _OFA_enable_or_disable(AVX512PF "avx512pf" "Use AVX512PF. This enables prefetch instructions for gathers and scatters." false)
            _OFA_enable_or_disable(AVX512ER "avx512er" "Use AVX512ER. This enables exponential and reciprocal instructions." false)
            _OFA_enable_or_disable(AVX512CD "avx512cd" "Use AVX512CD." false)
            _OFA_enable_or_disable(AVX512DQ "avx512dq" "Use AVX512DQ." false)
            _OFA_enable_or_disable(AVX512BW "avx512bw" "Use AVX512BW." false)
            _OFA_enable_or_disable(AVX512IFMA "avx512ifma" "Use AVX512IFMA." false)
            _OFA_enable_or_disable(AVX512VBMI "avx512vbmi" "Use AVX512VBMI." false)

            if(MSVC)
                # MSVC on 32 bit can select /arch:SSE2 (since 2010 also /arch:AVX)
                # MSVC on 64 bit cannot select anything (should have changed with MSVC 2010)
                list(FIND _enable_vector_unit_list "avx2" _found)
                if(_found LARGER -1)
                    if(CMAKE_CXX_COMPILER_LOADED)
                        _OFA_add_compiler_flag("/arch:AVX2" CXX_FLAGS ARCHITECTURE_FLAGS CXX_RESULT _found)
                    elseif(CMAKE_C_COMPILER_LOADED)
                        _OFA_add_compiler_flag("/arch:AVX2" C_FLAGS ARCHITECTURE_FLAGS C_RESULT _found)
                    endif()
                endif()
                if(NOT _found)
                    list(FIND _enable_vector_unit_list "avx" _found)
                    if(_found LARGER -1)
                        if(CMAKE_CXX_COMPILER_LOADED)
                            _OFA_add_compiler_flag("/arch:AVX" CXX_FLAGS ARCHITECTURE_FLAGS CXX_RESULT _found)
                        elseif(CMAKE_C_COMPILER_LOADED)
                            _OFA_add_compiler_flag("/arch:AVX" C_FLAGS ARCHITECTURE_FLAGS C_RESULT _found)
                        endif()
                    endif()
                endif()
                if(NOT _found)
                    list(FIND _enable_vector_unit_list "sse2" _found)
                    if(_found LARGER -1)
                        if(CMAKE_CXX_COMPILER_LOADED)
                            _OFA_add_compiler_flag("/arch:SSE2" CXX_FLAGS ARCHITECTURE_FLAGS)
                        elseif(CMAKE_C_COMPILER_LOADED)
                            _OFA_add_compiler_flag("/arch:SSE2" C_FLAGS ARCHITECTURE_FLAGS)
                        endif()
                    endif()
                endif()
                foreach(_flag ${_enable_vector_unit_list})
                    string(TOUPPER "${_flag}" _flag)
                    string(REPLACE "." "_" _flag "__${_flag}__")
                    add_definitions("-D${_flag}")
                endforeach()
            elseif(CMAKE_CXX_COMPILER MATCHES "/(icpc|icc)$") # ICC (on Linux)
                set(OFA_map_knl "-xMIC-AVX512")
                set(OFA_map_cannonlake "-xCORE-AVX512")
                set(OFA_map_skylake-avx512 "-xCORE-AVX512")
                set(OFA_map_skylake "-xCORE-AVX2")
                set(OFA_map_broadwell "-xCORE-AVX2")
                set(OFA_map_haswell "-xCORE-AVX2")
                set(OFA_map_ivybridge "-xCORE-AVX-I")
                set(OFA_map_sandybridge "-xAVX")
                set(OFA_map_westmere "-xSSE4.2")
                set(OFA_map_nehalem "-xSSE4.2")
                set(OFA_map_penryn "-xSSSE3")
                set(OFA_map_merom "-xSSSE3")
                set(OFA_map_core2 "-xSSE3")
                set(_ok FALSE)
                foreach(arch ${_march_flag_list})
                    if(DEFINED OFA_map_${arch})
                        if(CMAKE_CXX_COMPILER_LOADED)
                            _OFA_add_compiler_flag(${OFA_map_${arch}} CXX_FLAGS ARCHITECTURE_FLAGS CXX_RESULT _ok)
                        elseif(CMAKE_C_COMPILER_LOADED)
                            _OFA_add_compiler_flag(${OFA_map_${arch}} C_FLAGS ARCHITECTURE_FLAGS C_RESULT _ok)
                        endif()
                        if(_ok)
                            break()
                        endif()
                    endif()
                endforeach()
                if(NOT _ok)
                    # This is the Intel compiler, so SSE2 is a very reasonable baseline.
                    message(STATUS "${OFA_FUNCNAME}: Did not recognize the requested architecture flag, falling back to SSE2")
                    _OFA_add_compiler_flag("-xSSE2" CXX_FLAGS ARCHITECTURE_FLAGS)
                endif()
            else() # not MSVC and not ICC => GCC, Clang, Open64
                foreach(_flag ${_march_flag_list})
                    if(CMAKE_CXX_COMPILER_LOADED)
                        _OFA_add_compiler_flag("-march=${_flag}" CXX_RESULT _good CXX_FLAGS ARCHITECTURE_FLAGS)
                    elseif(CMAKE_C_COMPILER_LOADED)
                        _OFA_add_compiler_flag("-march=${_flag}" C_RESULT _good C_FLAGS ARCHITECTURE_FLAGS)
                    endif()
                    if(_good)
                        break()
                    endif(_good)
                endforeach()
                foreach(_flag ${_enable_vector_unit_list})
                    if(CMAKE_CXX_COMPILER_LOADED)
                        _OFA_add_compiler_flag("-m${_flag}" CXX_RESULT _result)
                    elseif(CMAKE_C_COMPILER_LOADED)
                        _OFA_add_compiler_flag("-m${_flag}" C_RESULT _result)
                    endif()
                    if(_result)
                        set(_header FALSE)
                        if(_flag STREQUAL "sse3")
                            set(_header "pmmintrin.h")
                        elseif(_flag STREQUAL "ssse3")
                            set(_header "tmmintrin.h")
                        elseif(_flag STREQUAL "sse4.1")
                            set(_header "smmintrin.h")
                        elseif(_flag STREQUAL "sse4.2")
                            set(_header "smmintrin.h")
                        elseif(_flag STREQUAL "sse4a")
                            set(_header "ammintrin.h")
                        elseif(_flag STREQUAL "avx")
                            set(_header "immintrin.h")
                        elseif(_flag STREQUAL "avx2")
                            set(_header "immintrin.h")
                        elseif(_flag STREQUAL "fma4")
                            set(_header "x86intrin.h")
                        elseif(_flag STREQUAL "xop")
                            set(_header "x86intrin.h")
                        endif()
                        set(_resultVar "HAVE_${_header}")
                        string(REPLACE "." "_" _resultVar "${_resultVar}")
                        if(_header)
                            if(CMAKE_CXX_COMPILER_LOADED)
                                check_include_file_cxx("${_header}" ${_resultVar} "-m${_flag}")
                            elseif(CMAKE_C_COMPILER_LOADED)
                                check_include_file("${_header}" ${_resultVar} "-m${_flag}")
                            endif()
                            if(NOT ${_resultVar})
                                set(_useVar "USE_${_flag}")
                                string(TOUPPER "${_useVar}" _useVar)
                                string(REPLACE "." "_" _useVar "${_useVar}")
                                message(STATUS "${OFA_FUNCNAME}: disabling ${_useVar} because ${_header} is missing")
                                set(${_useVar} FALSE)
                                list(APPEND _disable_vector_unit_list "${_flag}")
                            endif()
                        endif()
                        if(NOT _header OR ${_resultVar})
                            list(APPEND ARCHITECTURE_FLAGS "-m${_flag}")
                        endif()
                    endif()
                endforeach()
                foreach(_flag ${_disable_vector_unit_list})
                    if(CMAKE_CXX_COMPILER_LOADED)
                        _OFA_add_compiler_flag("-mno-${_flag}" CXX_FLAGS ARCHITECTURE_FLAGS)
                    elseif(CMAKE_C_COMPILER_LOADED)
                        _OFA_add_compiler_flag("-mno-${_flag}" C_FLAGS ARCHITECTURE_FLAGS)
                    endif()
                endforeach()
            endif()
        endif()
    else()
        message(WARNING "${OFA_FUNCNAME} does not support for CMAKE_SYSTEM_PROCESSOR: ${CMAKE_SYSTEM_PROCESSOR}")
    endif()
    set(${_outvar} ${ARCHITECTURE_FLAGS} PARENT_SCOPE)
endfunction()
