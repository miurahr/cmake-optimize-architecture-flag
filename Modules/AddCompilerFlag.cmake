# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#.rst:
# AddCompilerFlag
# ---------------
#
# Copyright 2018 Hiroshi Miura
# Copyright 2010-2015 Matthias Kretz <kretz@kde.org>
#
# - Add a given compiler flag to flags variables.
# AddCompilerFlag(<flag> [C_FLAGS <var>] [CXX_FLAGS <var>] [C_RESULT <var>]
#                        [CXX_RESULT <var>])

include("${CMAKE_CURRENT_LIST_DIR}/CheckCCompilerFlag.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/CheckCXXCompilerFlag.cmake")

function(AddCompilerFlag _flag)
    string(REGEX REPLACE "[-.+/:= ;]" "_" _flag_esc "${_flag}")
    set(_options)
    set(_oneValueArgs C_FLAGS CXX_FLAGS C_RESULT CXX_RESULT)
    set(_multiValueArgs)
    cmake_parse_arguments(_ACF "${_options}" "${_oneValueArgs}" "${_multiValueArgs}" ${ARGN})
    if(_ACF_C_FLAGS)
        set(_c_flags ${_ACF_C_FLAGS})
    else()
        set(_c_flags "CMAKE_C_FLAGS")
    endif()
    if(_ACF_CXX_FLAGS)
        set(_cxx_flags ${_ACF_C_FLAGS})
    else()
        set(_cxx_flags "CMAKE_CXX_FLAGS")
    endif()
    if(_ACF_C_RESULT)
        set(_c_result ${_ACF_C_RESULT})
    endif()
    if(_ACF_CXX_RESULT)
        set(_cxx_result ${_ACF_CXX_RESULT})
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
        set(${_c_result} ${check_c_compiler_flag_${_flag_esc}} PARENT_SCOPE)
    endif()
    if(DEFINED _cxx_result)
        check_cxx_compiler_flag("${_flag}" check_cxx_compiler_flag_${_flag_esc} "${_cxx_code}")
        set(${_cxx_result} ${check_cxx_compiler_flag_${_flag_esc}} PARENT_SCOPE)
    endif()

    macro(my_append _list _flag _special)
        if("x${_list}" STREQUAL "x${_special}")
            string(APPEND ${_list} "${_flag}")
        else()
            list(APPEND ${_list} "${_flag}")
        endif()
    endmacro()

    if(check_c_compiler_flag_${_flag_esc} AND DEFINED _c_flags)
        my_append(${_c_flags} "${_flag}" CMAKE_C_FLAGS)
        set(${_c_flags} "${_c_flags}" PARENT_SCOPE)
    endif()
    if(check_cxx_compiler_flag_${_flag_esc} AND DEFINED _cxx_flags)
        my_append(${_cxx_flags} "${_flag}" CMAKE_CXX_FLAGS)
        set(${_cxx_flags} "${_cxx_flags}" PARENT_SCOPE)
    endif()
endfunction()
