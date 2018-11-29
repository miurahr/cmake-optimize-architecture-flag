# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:
CheckCPUFeature
---------------

Check CPU feature

.. command:: check_cpu_feature

   check_cpu_feature(<out variable> <feature key>)

#]=======================================================================]

function(CHECK_CPU_FEATURE outvar feature)
  if(NOT _check_cpu_feature_values)
    set(_cpu_flags)
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        file(READ "/proc/cpuinfo" _cpuinfo)
        string(REGEX REPLACE ".*flags[ \t]*:[ \t]+([^\n]+).*" "\\1" _cpu_flags "${_cpuinfo}")
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
      execute_process(COMMAND "/usr/sbin/sysctl -n machdep.cpu.features"
                      OUTPUT_VARIABLE _cpu_flags
                      ERROR_QUIET
                      OUTPUT_STRIP_TRAILING_WHITESPACE)
      string(TOLOWER "${_cpu_flags}" _cpu_flags)
      string(REPLACE "." "_" _cpu_flags "${_cpu_flags}")
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
      try_run(RUN_RESULT COMP_RESULT ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_LIST_DIR}/win32_cpuinfo.c
              CMAKE_FLAGS -g
              RUN_OUTPUT_VARIABLE flags)
      message(STATUS "Detected features: ${flags}")

    elseif(CMAKE_SYSTEM_NAME STREQUAL "OpenBSD" OR
           CMAKE_SYSTEM_NAME STREQUAL "FreeBSD" OR
           CMAKE_SYSTME_NAME STREQUAL "NetBSD")
      execute_process("grep Features /var/run/dmesg.boot"
                      OUTPUT_VARIABLE _cpu_features
                      ERROR_QUIET
                      OUTPUT_STRIP_TRAILING_WHITESPACE)
      string(REGEX REPLACE ".*=0x[0-9a-f]+<[ \t]+([^\n]+).*" "\\1" _cpu_flags "${_cpu_features}")
      string(REPLACE "\n" ";" _cpu_flags "${_cpu_features}")
      string(TOLOWER "${_cpu_flags}" _cpu_flags)
    endif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    string(REPLACE " " ";" _cpu_flags "${_cpu_flags}")
    set(_check_cpu_feature_values ${_cpu_flags} CACHE INTERNAL "cache for internal function")
  endif()
  list(FIND _check_cpu_feature_values ${feature} _found)
  if(_found GREATER -1)
    set(${outvar} 1 PARENT_SCOPE)
  else()
    set(${outvar} 0 PARENT_SCOPE)
  endif()
endfunction()
