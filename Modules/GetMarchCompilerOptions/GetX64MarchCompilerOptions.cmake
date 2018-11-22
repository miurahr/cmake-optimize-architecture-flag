# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:
GetX64MarchCompilerOptions
--------------------------

  Get march flags for target Intel micro architecture

.. command:: get_x64_march_compiler_options

   get_x64_march_compiler_options(<output variable> <target architecture>)

#]=======================================================================]

include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)
include(CheckIncludeFileCXX)
include(CheckIncludeFile)

include("${CMAKE_CURRENT_LIST_DIR}/../GetCPUSIMDFeatures.cmake")

function(GET_X64_MARCH_COMPILER_OPTIONS outvar tarch)
    macro(__check_compiler_flag _flag _result)
        if(CMAKE_CXX_COMPILER_LOADED)
            check_cxx_compiler_flag("${_flag}" ${_result})
        elseif(CMAKE_C_COMPILER_LOADED)
            check_c_compiler_flag("${_flag}" ${_result})
        endif()
    endmacro()

    set(ARCHITECTURE_FLAGS)

    set(merom_fallback "core2")
    set(penryn_fallback "core2")
    set(atom_fallback "core2")
    set(knl_fallback "broadwell" "haswell" "core-avx2" "ivybridge" "core-avx-i" "sandybridge" "corei7-avx" "core2")
    set(knm_fallback "broadwell" "haswell" "core-avx2" "ivybridge" "core-avx-i" "sandybridge" "corei7-avx" "core2")
    set(cannonlake_fallback "skylake-avx512" "skylake" "broadwell" "haswell" "core-avx2" "ivybridge" "core-avx-i" "sandybridge" "corei7-avx" "core2")
    set(skylake_fallback "broadwell" "haswell" "core-avx2" "ivybridge" "core-avx-i" "sandybridge" "corei7-avx" "core2")
    set(kabylake_fallback "skylake" "broadwell" "haswell" "core-avx2" "ivybridge" "core-avx-i" "sandybridge" "corei7-avx" "core2")
    set(skylake-xeon_fallback "skylake-avx512" "skylake" "broadwell" "haswell" "core-avx2" "ivybridge" "core-avx-i" "sandybridge" "corei7-avx" "core2")
    set(skylake-avx512 "skylake" "broadwell" "haswell" "core-avx2" "ivybridge" "core-avx-i" "sandybridge" "corei7-avx" "core2")
    set(skylake_fallback "broadwell" "haswell" "core-avx2" "ivybridge" "core-avx-i" "sandybridge" "corei7-avx" "core2")
    set(broadwell_fallback "haswell" "core-avx2" "ivybridge" "core-avx-i" "sandybridge" "corei7-avx" "core2")
    set(haswell_fallback "ivybridge" "core-avx-i" "sandybridge" "core-avx2" "corei7-avx" "core2")
    set(ivybridge_fallback "ivybridge" "sandybridge" "corei7-avx" "core2")
    set(sandybridge_fallback "corei7-avx" "core2")
    set(westmere_fallback "nehalem" "corei7" "core2")
    set(nehalem_fallback "corei7" "core2")
    set(goldmont_fallback "silvermont" "westmere" "corei7" "core2")
    set(silvermont_fallback "westmere" "corei7" "core2")
    set(k8-sse3_fallback "k8")
    set(amd-16h_fallback "btver2" "btver1")
    set(amd-14h_fallback "btver1")
    set(zen_fallback "znver1" "skylake" "broadwell" "haswell" "core-avx2" "ivybridge" "core-avx-i" "sandybridge" "corei7-avx" "core2")
    set(piledriver_fallback "bdver2" "bdver1" "bulldozer" "barcelona" "core2")
    set(interlagos_fallback "bdver2" "bdver1" "bulldozer" "barcelona" "core2")
    set(barcelona_fallback "core2")
    set(istanbul_fallback "barcelona" "core2")
    set(magny-cours_fallback "barcelona" "core2")

    if(tarch STREQUAL "none")
        message(WARNING "Unsupported target architecture. No flag is added.")
    elseif(tarch STREQUAL "Generic")
        # skip
    else()
        if(DEFINED ${tarch}_fallback)
            set(_march_flag_list "${tarch}" ${${tarch}_fallback})
        else()
            set(_march_flag_list "${tarch}")
        endif()
        get_cpu_simd_features(_enable_vector_unit_list ${tarch})
        set(_disable_vector_unit_list)

        if(MSVC)
            # Only Visual Studio 2017 version 15.3 / Visual C++ 19.11 & up have support for AVX-512.
            # https://blogs.msdn.microsoft.com/vcblog/2017/07/11/microsoft-visual-studio-2017-supports-intel-avx-512/
            list(FIND _enable_vector_unit_list "avx512" _found)
            if(_found GREATER -1)
                __check_compiler_flag("-arch:AVX512" _found)
                if(__found)
                    list(APPEND ARCHITECTURE_FLAGS "-arch:AVX512")
                endif()
            endif()
            list(FIND _enable_vector_unit_list "avx2" _found)
            if(_found GREATER -1)
                __check_compiler_flag("/arch:AVX2" _found)
                if(__found)
                    list(APPEND ARCHITECTURE_FLAGS "/arch:AVX2")
                endif()
            endif()
            if(NOT _found)
                list(FIND _enable_vector_unit_list "avx" _found)
                if(_found GREATER -1)
                    __check_compiler_flag("/arch:AVX" _found)
                    if(__found)
                        list(APPEND ARCHITECTURE_FLAGS "/arch:AVX")
                    endif()
                endif()
            endif()
            if(NOT _found)
                list(FIND _enable_vector_unit_list "sse2" _found) # default
                if(_found EQUAL -1)
                    list(FIND _enable_vector_unit_list "sse" _found) # default
                    if(_found EQUAL -1)
                        # there is no SSE2 support
                        __check_compiler_flag("/arch:SSE" _ok)
                        if(_ok)
                            list(APPEND ARCHITECTURE_FLAGS "/arch:SSE")
                        endif()
                    else()
                        __check_compiler_flag("/arch:IA32" _ok)
                        if(_ok)
                            list(APPEND ARCHITECTURE_FLAGS "/arch:IA32")
                        endif()
                    endif()
                endif()
            endif()
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
                    __check_compiler_flag(${OFA_map_${arch}} _ok)
                    if(_ok)
                        list(APPEND ARCHITECTURE_FLAGS ${OFA_map_${arch}})
                        break()
                    endif()
                endif()
            endforeach()
            if(NOT _ok)
                # This is the Intel compiler, so SSE2 is a very reasonable baseline.
                message(STATUS "Did not recognize the requested architecture flag, falling back to SSE2")
                list(APPEND ARCHITECTURE_FLAGS "-xSSE2")
            endif()
        else() # not MSVC and not ICC => GCC, Clang, Open64
            foreach(_arch ${_march_flag_list})
                __check_compiler_flag("-march=${_arch}" test_${_arch})
                if(test_${_arch})
                    list(APPEND ARCHITECTURE_FLAGS "-march=${_arch}")
                    break()
                endif()
            endforeach()
            foreach(_flag ${_enable_vector_unit_list})
                __check_compiler_flag("-m${_flag}" test_${_flag})
                if(test_${_flag})
                    set(header_table "sse3" "pmmintrin.h" "ssse3" "tmmintrin.h" "sse4.1" "smmintrin.h"
                        "sse4.2" "smmintrin.h" "sse4a" "ammintrin.h" "avx" "immintrin.h"
                        "avx2" "immintrin.h" "fma4" "x86intrin.h" "xop" "x86intrin.h")
                    set(_header FALSE)
                    list(FIND header_table ${_flag} _found)
                    if(_found GREATER -1)
                        math(EXPR index "${_found} + 1")
                        list(GET header_table ${index} _header)
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
                            list(APPEND _disable_vector_unit_list "${_flag}")
                        endif()
                    endif()
                    if(NOT _header OR ${_resultVar})
                        list(APPEND ARCHITECTURE_FLAGS "-m${_flag}")
                    endif()
                endif()
            endforeach()
            foreach(_flag ${_disable_vector_unit_list})
                __check_compiler_flag("-mno-${_flag}" test_no_${_flag})
                if(test_no_${_flag})
                    list(APPEND ARCHITECTURE_FLAGS "-mno-${_flag}")
                endif()
            endforeach()
        endif()
    endif()
    set(${outvar} ${ARCHITECTURE_FLAGS} PARENT_SCOPE)
endfunction()

