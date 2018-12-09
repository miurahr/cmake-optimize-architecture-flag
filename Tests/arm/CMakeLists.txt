cmake_minimum_required (VERSION 3.5)

if(POLICY CMP0066)
    cmake_policy(SET CMP0066 NEW)
endif()

project(CMakeHostSystemInformationExtra_TEST_ARM VERSION 1.0 LANGUAGES C)
include(CMakeHostSystemInformationExtra)

# ARM test only works on Linux
if(CMAKE_HOST_SYSTEM_NAME MATCHES "Linux")

set(TEST_CPUINFO_1  # Amazon A1 instance
"processor	     : 0
BogoMIPS	      : 166.66
Features	      : fp asimd evtstrm aes pmull sha1 sha2 crc32 cpuid
CPU implementer : 0x41
CPU architecture: 8
CPU variant	    : 0x0
CPU part	      : 0xd08
CPU revision	  : 3
")
set(TEST_EXPECT_1 "Cortex-A72")
set(TEST_FEATURE_1 "neon")

set(TEST_CPUINFO_2 # MSM7227 processor
    "Processor : ARMv6-compatible processor rev 5 (v6l)
BogoMIPS : 245.61
Features : swp half thumb fastmult vfp edsp java
CPU implementer : 0x41
CPU architecture: 6TEJ
CPU variant : 0x1
CPU part : 0xb36
CPU revision : 5
")
set(TEST_EXPECT_2 "ARM1136")
set(TEST_FEATURE_2 "thumb")

set(TEST_CPUINFO_3 # RPi B+/BCM2708
"model name : ARMv6-compatible processor rev 7 (v6l)
Features : half thumb fastmult vfp edsp java tls
CPU implementer : 0x41
CPU architecture: 7
CPU variant : 0x0
CPU part : 0xb76
CPU revision : 7
")
set(TEST_EXPECT_3 "ARM1176")
set(TEST_FEATURE_3 "java")

set(TEST_CPUINFO_4 # NanoPi NEO
"Processor : ARMv7 Processor rev 5 (v7l)
Features : swp half thumb fastmult vfp edsp thumbee neon vfpv3 tls vfpv4 idiva idivt
CPU implementer : 0x41
CPU architecture: 7
CPU variant : 0x0
CPU part : 0xc07
CPU revision : 5
")
set(TEST_EXPECT_4 "Cortex-A7")
set(TEST_FEATURE_4 "vfpv4")

set(TEST_CPUINFO_5 #Sony XPERIA C1905
"Processor	: ARMv7 Processor rev 4 (v7l)
Features	: swp half thumb fastmult vfp edsp neon vfpv3 tls vfpv4
CPU implementer	: 0x51
CPU architecture: 7
CPU variant	: 0x1
CPU part	: 0x04d
CPU revision	: 4
")
set(TEST_EXPECT_5 "Krait") # QCT MSM8627 MTP
set(TEST_FEATURE_5 "vfpv4")

set(TEST_CPUINFO_6 # OMAP4 jet board
"Processor   : ARMv7 Processor rev 3 (v7l)
Features    : swp half thumb fastmult vfp edsp thumbee neon vfpv3
CPU implementer : 0x41
CPU architecture: 7
CPU variant : 0x1
CPU part    : 0xc09
CPU revision    : 3
")
set(TEST_EXPECT_6 "Cortex-A9")
set(TEST_FEATURE_6 "neon")

set(TEST_CPUINFO_7   # ARM Cortex A53 (octa-core):
"Processor   : AArch64 Processor rev 3 (aarch64)
processor   : 0
processor   : 1
processor   : 2
processor   : 3
processor   : 4
processor   : 5
processor   : 6
processor   : 7
Features    : fp asimd evtstrm aes pmull sha1 sha2 crc32
CPU implementer : 0x41
CPU architecture: AArch64
CPU variant : 0x0
CPU part    : 0xd03
CPU revision    : 3
")
set(TEST_EXPECT_7 "Cortex-A53")
set(TEST_FEATURE_7 "neon")

set(TEST_CPUINFO_8 # Freescale i.MX6 Quad/DualLite (Device Tree)
"model name      : ARMv7 Processor rev 10 (v7l)
BogoMIPS        : 3.00
Features        : half thumb fastmult vfp edsp neon vfpv3 tls vfpd32
CPU implementer : 0x41
CPU architecture: 7
CPU variant     : 0x2
CPU part        : 0xc09
CPU revision    : 10
")
set(TEST_EXPECT_8 "Cortex-A9")
set(TEST_FEATURE_8 "neon")

foreach(testno IN ITEMS 1 2 3 4 5 6 7 8)
  set(_PROC_CPUINFO "/tmp/CmakeHostSystemInformationExtra__test__cpuinfo")
  file(WRITE ${_PROC_CPUINFO} "${TEST_CPUINFO_${testno}}")
  detect_arm_micro_architecture(arg1 arg2 arg3)
  if(arg2 MATCHES "${TEST_EXPECT_${testno}}")
    message(STATUS "Test ${testno} passed for ${arg2}")
  else()
    message(FATAL_ERROR "Test ${testno} got unexpected result: ${arg2}.")
  endif()

  check_cpu_feature(res "${TEST_FEATURE_${testno}}")
  if(res)
    message(STATUS "Found ${TEST_FEATURE_${testno}}")
  else()
    message(FATAL_ERROR "Test Feature ${testno}: ${TEST_FEATURE_${testno}} failed.")
  endif()
endforeach()

endif()

# vim: ts=2 sw=2 sts=2 et
