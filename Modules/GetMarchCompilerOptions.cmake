# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:
GetMarchCompilerOptions
--------------------------

  Get march flags for target Intel micro architecture

.. command:: get_march_compiler_options

   get_march_compiler_options(<output variable> <target architecture>)

#]=======================================================================]

include("${CMAKE_CURRENT_LIST_DIR}/GetMarchCompilerOptions/GetX64MarchCompilerOptions.cmake")

function(GET_MARCH_COMPILER_OPTIONS outvar tarch)
    set(compiler_options)
    if("${CMAKE_SYSTEM_PROCESSOR}" MATCHES "(x86|AMD64)")
        get_x64_march_compiler_options(compiler_options ${tarch})
    elseif("${CMAKE_SYSTEM_PROCESSOR}" MATCHES "ARM")
        # FIXME implement me
        get_arm_march_compiler_options(compiler_options ${tarch})
    endif()
    set(${outvar} ${compiler_options} PARENT_SCOPE)
endfunction()