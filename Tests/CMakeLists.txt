
if(CMAKE_HOST_SYSTEM_NAME MATCHES "Linux")
  add_subdirectory(CMakeHostSystemInformationExtra)
endif()
add_subdirectory(CMakeCompilerMachineOption)
