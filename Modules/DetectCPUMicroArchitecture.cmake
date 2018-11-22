# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:
DetectCPUMicroArchitecture
-------------------------

  Detect CPU micro architecture and return a code name

.. command:: detect_cpu_micro_architecture

   detect_cpu_micro_architecture(<output variable name>)

  Determine the host CPU micro architecture and retrun a code name.
  Currently support only Intel x86/x64 architecture.

#]=======================================================================]

include("${CMAKE_CURRENT_LIST_DIR}/DetectCPUMicroArchitecture/DetectX64MicroArchitecture.cmake")

function(DETECT_CPU_MICRO_ARCHITECTURE outvar)
    set(detected_architecture)
    if("${CMAKE_SYSTEM_PROCESSOR}" MATCHES "(x86|AMD64)")
        detect_x64_micro_architecture(detected_architecture)
    elseif("${CMAKE_SYSTEM_PROCESSOR}" MATCHES "ARM")
        # FIXME implement me
        detect_arm_micro_architecture(detected_architecture)
    endif()
    set(${outvar} ${detected_architecture} PARENT_SCOPE)
endfunction()
