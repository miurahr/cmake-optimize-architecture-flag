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
    if(NOT "${CMAKE_SYSTEM_PROCESSOR}" MATCHES "(ARM|ARM64)")
        return()
    endif()

    set(_vendor_id)
    set(_cpu_family)
    set(_cpu_model)
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux") # Linux and Android
        file(READ "/proc/cpuinfo" _cpuinfo)
        string(REGEX REPLACE ".*CPU implementer[ \t]*:[ \t]+([a-zA-Z0-9_-]+).*" "\\1" _cpu_implementer "${_cpuinfo}")
        string(REGEX REPLACE ".*CPU architecture[ \t]*:[ \t]+([a-zA-Z0-9_-]+).*" "\\1" _cpu_architecture "${_cpuinfo}")
        string(REGEX REPLACE ".*CPU variant[ \t]*:[ \t]+([a-zA-Z0-9_-]+).*" "\\1" _cpu_variant "${_cpuinfo}")
        string(REGEX REPLACE ".*Features[ \t]*:[ \t]+([^\n]+).*" "\\1" _cpu_features "${_cpuinfo}")
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
    #[=======================================================================[.rst:

      	Full list of ARM features reported in /proc/cpuinfo

      	* swp - support for SWP instruction (deprecated in ARMv7, can be removed in future)
      	* half - support for half-word loads and stores. These instruction are part of ARMv4,
      	         so no need to check it on supported CPUs.
      	* thumb - support for 16-bit Thumb instruction set. Note that BX instruction is detected
      	          by ARMv4T architecture, not by this flag.
      	* 26bit - old CPUs merged 26-bit PC and program status register (flags) into 32-bit PC
      	          and had special instructions for working with packed PC. Now it is all deprecated.
      	* fastmult - most old ARM CPUs could only compute 2 bits of multiplication result per clock
      	             cycle, but CPUs with M suffix (e.g. ARM7TDMI) could compute 4 bits per cycle.
      	             Of course, now it makes no sense.
      	* fpa - floating point accelerator available. On original ARM ABI all floating-point operations
      	        generated FPA instructions. If FPA was not available, these instructions generated
      	        "illegal operation" interrupts, and the OS processed them by emulating the FPA instructions.
      	        Debian used this ABI before it switched to EABI. Now FPA is deprecated.
      	* vfp - vector floating point instructions. Available on most modern CPUs (as part of VFPv3).
      	        Required by Android ARMv7A ABI and by Ubuntu on ARM.
                    Note: there is no flag for VFPv2.
      	* edsp - V5E instructions: saturating add/sub and 16-bit x 16-bit -> 32/64-bit multiplications.
      	         Required on Android, supported by all CPUs in production.
      	* java - Jazelle extension. Supported on most CPUs.
      	* iwmmxt - Intel/Marvell Wireless MMX instructions. 64-bit integer SIMD.
      	           Supported on XScale (Since PXA270) and Sheeva (PJ1, PJ4) architectures.
      	           Note that there is no flag for WMMX2 instructions.
      	* crunch - Maverick Crunch instructions. Junk.
      	* thumbee - ThumbEE instructions. Almost no documentation is available.
      	* neon - NEON instructions (aka Advanced SIMD). MVFR1 register gives more
      	         fine-grained information on particular supported features, but
      	         the Linux kernel exports only a single flag for all of them.
      	         According to ARMv7A docs it also implies the availability of VFPv3
      	         (with 32 double-precision registers d0-d31).
      	* vfpv3 - VFPv3 instructions. Available on most modern CPUs. Augment VFPv2 by
      	          conversion to/from integers and load constant instructions.
      	          Required by Android ARMv7A ABI and by Ubuntu on ARM.
      	* vfpv3d16 - VFPv3 instructions with only 16 double-precision registers (d0-d15).
      	* tls - software thread ID registers.
      	        Used by kernel (and likely libc) for efficient implementation of TLS.
      	* vfpv4 - fused multiply-add instructions.
      	* idiva - DIV instructions available in ARM mode.
      	* idivt - DIV instructions available in Thumb mode.
        * vfpd32 - VFP (of any version) with 32 double-precision registers d0-d31.
        * lpae - Large Physical Address Extension (physical address up to 40 bits).
        * evtstrm - generation of Event Stream by timer.
        * aes - AES instructions.
        * pmull - Polinomial Multiplication instructions.
        * sha1 - SHA1 instructions.
        * sha2 - SHA2 instructions.
        * crc32 - CRC32 instructions.

      	/proc/cpuinfo on ARM is populated in file arch/arm/kernel/setup.c in Linux kernel
      	Note that some devices may use patched Linux kernels with different feature names.
      	However, the names above were checked on a large number of /proc/cpuinfo listings.

      	source: https://github.com/pytorch/cpuinfo/blob/master/src/arm/linux/cpuinfo.c
    #]=======================================================================]

    # TODO implement me
    set(${outvar} "${MICRO_ARCHITECTURE}" PARENT_SCOPE)
endfunction()
