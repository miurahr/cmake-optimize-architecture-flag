add_test(NAME "CMakeCompilerMachineOption.self"
         COMMAND "${CMAKE_CTEST_COMMAND}"
         --build-and-test
         "${CMAKE_SOURCE_DIR}/Tests/CMakeCompilerMachineOption/self"
         "${CMAKE_BINARY_DIR}/Tests/CMakeCompilerMachineOption/self"
         --build-two-config
         --build-generator ${CMAKE_GENERATOR}
         --build-project CMakeCompilerMachineOption
         --build-options -DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/Modules
         )
add_test(NAME "CMakeCompilerMachineOption.cross"
         COMMAND "${CMAKE_CTEST_COMMAND}"
         --build-and-test
         "${CMAKE_SOURCE_DIR}/Tests/CMakeCompilerMachineOption/cross"
         "${CMAKE_BINARY_DIR}/Tests/CMakeCompilerMachineOption/cross"
         --build-two-config
         --build-generator ${CMAKE_GENERATOR}
         --build-project CMakeCompilerMachineOption
         --build-options
           -DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/Modules
           -DTARGET_ARCHITECTURE="skylake"
         )