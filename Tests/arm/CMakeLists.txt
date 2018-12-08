cmake_minimum_required (VERSION 3.5)

if(POLICY CMP0066)
    cmake_policy(SET CMP0066 NEW)
endif()

project(CMakeHostSystemInformationExtra_TEST_ARM VERSION 1.0 LANGUAGES C)
include(CMakeHostSystemInformationExtra)

# ARM test only works on Linux
if(CMAKE_HOST_SYSTEM_NAME MATCHES "Linux")

set(TEST_CPUINFO_1 "processor	     : 0
BogoMIPS	      : 166.66
Features	      : fp asimd evtstrm aes pmull sha1 sha2 crc32 cpuid
CPU implementer : 0x41
CPU architecture: 8
CPU variant	    : 0x0
CPU part	      : 0xd08
CPU revision	  : 3
")
set(TEST_EXPECT_1 "Cortex-A72")
set(TEST_CPUINFO_2 "Processor : ARMv6-compatible processor rev 5 (v6l)
BogoMIPS : 245.61
Features : swp half thumb fastmult vfp edsp java
CPU implementer : 0x41
CPU architecture: 6TEJ
CPU variant : 0x1
CPU part : 0xb36
CPU revision : 5
")
set(TEST_EXPECT_2 "ARM1136")

foreach(testno IN ITEMS 1 2)
  set(_PROC_CPUINFO "/tmp/CmakeHostSystemInformationExtra__test__cpuinfo")
  file(WRITE ${_PROC_CPUINFO} "${TEST_CPUINFO_${testno}}")
  detect_arm_micro_architecture(arg1 arg2 arg3)
  if(arg2 MATCHES "${TEST_EXPECT_${testno}}")
    message(STATUS "Test ${testno} passed for ${arg2}")
  else()
    message(FATAL_ERROR "Test ${testno} got unexpected result: ${arg2}.")
  endif()
endforeach()

endif()

# vim: ts=2 sw=2 sts=2 et
