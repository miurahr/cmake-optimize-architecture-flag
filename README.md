# Optimize cflags for architecture features

[![Build Status](https://travis-ci.org/miurahr/cmake-optimize-architecture-flag.svg?branch=master)](https://travis-ci.org/miurahr/cmake-optimize-architecture-flag)
[![Build status](https://ci.appveyor.com/api/projects/status/3xbllgket0ws79dw?svg=true)](https://ci.appveyor.com/project/miurahr/cmake-optimize-architecture-flag)

Here is a cmake module and sample program to optimize architecture features
such as a SIMD extensions.

## How to use?

1. Place cmake scripts under `Modules` folder in your project and add search path
in your `CMakeLists.txt` by setting `CMAKE_MODULE_PATH` variable.

2. Include script using 

```
include(CMakeHostSystemInformationExtra)
include(GetCPUSIMDFeatures)
include(CMakeCompilerMachineOption)
```
in your `CMakeLists.txt`

3. Call function `cmake_host_system_information_extra(RESULT <output variable name> QUERY <query> ...)`
to detect host system information.

4. Optimize compiler options

  Here is an example to optimize example project for skylake generation of Intel CPU.
```
set(TARGET_ARCHITECTURE skylake)
cmake_compiler_machine_option(ARCHITECTURE_FLAG ${TARGET_ARCHITECTURE})
message(STATUS "Use compiler option: ${ARCHITECTURE_FLAG}")
add_executable(example example.c)
target_compile_options(example PRIVATE ${ARCHITECTURE_FLAG})
```
Please see CMakeLists.txt for more details.

## License

This is distributed under OSI-Approved 3-Clause BSD license.
