cmake_minimum_required(VERSION 3.16 FATAL_ERROR)
project(SonyHeadphonesClient C CXX)

set(CMAKE_CXX_STANDARD 20)

option(MDR_BUILD_WITH_ASAN "Build with Address Sanitizer enabled" OFF)
if (MDR_BUILD_WITH_ASAN)
    add_compile_options("-fsanitize=address")
    add_link_options("-fsanitize=address")
endif ()

option(MDR_DEBUG "Build with debug flags enabled" OFF)
if (MDR_DEBUG)
    message(STATUS "Debugging features *ON*. Enjoy the logs.")
   add_compile_definitions(-DMDR_DEBUG)
   add_compile_definitions(-D_DEBUG)
endif ()

add_compile_options("-Wall" "-Wno-unused-function" "-Wno-unused-variable")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}")

include(DetectPlatform.cmake)
MDR_DetectPlatform() # Sets MDR_PLATFORM_OS
include(DetectGitInfo.cmake)
MDR_DetectGitInfo() # Sets MDR_GIT_COMMIT_HASH and MDR_GIT_BRANCH_NAME
add_compile_definitions("MDR_PLATFORM_${MDR_PLATFORM_OS}")

add_subdirectory(contrib)
add_subdirectory(libmdr)

# NOTE: Codegen is NOT automatically run when building the project itself.
# Should you make changes to the sources, see 'tooling/README.md' for instructions on how to run the codegen.
add_subdirectory(tooling)
