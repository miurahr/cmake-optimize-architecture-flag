# Optimize cflags for architecture features

Here is a cmake module and sample program to optimize architecture features
such as a SIMD extensions.

## How to use?

1. Place cmake scripts under `Modules` folder in your project and add search path
in your `CMakeLists.txt` by setting `CMAKE_MODULE_PATH` variable.

3. Include script using `include(OptimizeArchitectureFlag)` in your `CMakeLists.txt`

5. Call function `optimize_arch_flag(<output variable name>)`.


