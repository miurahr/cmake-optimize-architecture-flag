# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:
CheckCPUFeature
---------------

Check CPU feature

.. command:: check_cpu_feature

   check_cpu_feature(<out variable> <feature key>)

..note:
  It also alias names for features.
  /proc/cpuinfo reports `neon` as `asimd` in ARMv8-A architcture
  Linux reports SSE3 as `pni` as of prescot new instruction sets.

#]=======================================================================]

function(CHECK_CPU_FEATURE outvar feature)
  if(NOT _check_cpu_feature_values)
    set(_cpu_flags)
    if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
        file(READ "/proc/cpuinfo" _cpuinfo)
        string(REGEX REPLACE ".*flags[ \t]*:[ \t]+([^\n]+).*" "\\1" _cpu_flags "${_cpuinfo}")
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
      execute_process(COMMAND "/usr/sbin/sysctl -n machdep.cpu.features"
                      OUTPUT_VARIABLE _cpu_flags
                      ERROR_QUIET
                      OUTPUT_STRIP_TRAILING_WHITESPACE)
      string(TOLOWER "${_cpu_flags}" _cpu_flags)
      string(REPLACE "." "_" _cpu_flags "${_cpu_flags}")
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
      if("${CMAKE_HOST_SYSTEM_PROCESSOR}" MATCHES "(x86|AMD64)")
        try_run(RUN_RESULT COMP_RESULT ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_LIST_DIR}/win32_cpufeatures.c
                CMAKE_FLAGS -g
                RUN_OUTPUT_VARIABLE flags)
        message(STATUS "Detected features: ${flags}")
      elseif("${CMAKE_HOST_SYSTEM_PROCESSOR}" MATCHES "ARM")
        # TODO implement me.
        # Win on ARM requires thumb2+NEON at least.
        set(flags "neon" "thumb2")
      endif()
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "OpenBSD" OR
           CMAKE_HOST_SYSTEM_NAME STREQUAL "FreeBSD" OR
           CMAKE_HOST_SYSTME_NAME STREQUAL "NetBSD")
      execute_process("grep Features /var/run/dmesg.boot"
                      OUTPUT_VARIABLE _cpu_features
                      ERROR_QUIET
                      OUTPUT_STRIP_TRAILING_WHITESPACE)
      string(REGEX REPLACE ".*=0x[0-9a-f]+<[ \t]+([^\n]+).*" "\\1" _cpu_flags "${_cpu_features}")
      string(REPLACE "\n" ";" _cpu_flags "${_cpu_features}")
      string(TOLOWER "${_cpu_flags}" _cpu_flags)
    else()
      if(CMAKE_COMPILER_IS_GNUCC)
        try_run(RUN_RESULT COMP_RESULT ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_LIST_DIR}/gcc_cpufeatures.c
                CMAKE_FLAGS -g
                RUN_OUTPUT_VARIABLE flags)
        message(STATUS "Detected features: ${flags}")
      else()
        set(${outvar} 0 PARENT_SCOPE)
        return()
      endif()
    endif()
    string(REPLACE " " ";" _cpu_flags "${_cpu_flags}")
    set(_check_cpu_feature_values ${_cpu_flags} CACHE INTERNAL "cache for internal function")
  endif()
  # set alias
  if(feature STREQUAL neon)
    list(APPEND feature asimd)
  endif()
  if(feature STREQUAL sse3)
    list(APPEND feature pni)
  endif()
  foreach(item IN ITEMS ${feature})
    list(FIND _check_cpu_feature_values ${item} _found)
    if(_found GREATER -1)
      set(_found 1)
      break()
    else()
      set(_found 0)
    endif()
  endforeach()
  set(${outvar} ${_found} PARENT_SCOPE)
endfunction()
