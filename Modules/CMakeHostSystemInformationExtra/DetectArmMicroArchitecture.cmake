# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:
DetectArmMicroArchitecture
-------------------------

  Detect CPU micro architecture and return a code name

.. command:: detect_arm_micro_architecture

   detect_arm_micro_architecture(<output variable name>)

  Determine the host ARM CPU micro architecture and retrun
  a code name.

#]=======================================================================]

function(DETECT_ARM_MICRO_ARCHITECTURE outvar)
  set(_vendor_id)
  set(_cpu_family)
  set(_cpu_model)
  if(CMAKE_SYSTEM_NAME STREQUAL "Linux") # Linux and Android
    file(READ "/proc/cpuinfo" _cpuinfo)
    string(REGEX REPLACE ".*CPU implementer[ \t]*:[ \t]+([a-zA-Z0-9_-]+).*" "\\1" _cpu_implementer "${_cpuinfo}")
    string(REGEX REPLACE ".*CPU architecture[ \t]*:[ \t]+([a-zA-Z0-9_-]+).*" "\\1" _cpu_architecture "${_cpuinfo}")
    string(REGEX REPLACE ".*CPU variant[ \t]*:[ \t]+([a-zA-Z0-9_-]+).*" "\\1" _cpu_variant "${_cpuinfo}")
    string(REGEX REPLACE ".*Features[ \t]*:[ \t]+([^\n]+).*" "\\1" _cpu_features "${_cpuinfo}")
    set(MICRO_ARCHITECTURE "${_cpu_architecture}")
  elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    exec_program("/usr/sbin/sysctl -n machdep.cpu.vendor machdep.cpu.model machdep.cpu.family machdep.cpu.features" OUTPUT_VARIABLE _sysctl_output_string)
    string(REPLACE "\n" ";" _sysctl_output ${_sysctl_output_string})
    list(GET _sysctl_output 0 _vendor_id)
    list(GET _sysctl_output 1 _cpu_model)
    list(GET _sysctl_output 2 _cpu_family)
    list(GET _sysctl_output 3 _cpu_flags)
    string(TOLOWER "${_cpu_flags}" _cpu_flags)
    string(REPLACE "." "_" _cpu_flags "${_cpu_flags}")
    set(MICRO_ARCHITECTURE "${_cpu_family}")
  elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    get_filename_component(_cpu_id "[HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\CentralProcessor\\0;Identifier]" NAME CACHE)
    string(REGEX REPLACE ".* Family ([0-9]+) .*" "\\1" _cpu_family "${_cpu_id}")
    set(MICRO_ARCHITECTURE "${_cpu_family}")
  endif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  set(${outvar} "${MICRO_ARCHITECTURE}" PARENT_SCOPE)
endfunction()
