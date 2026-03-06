cmake_minimum_required(VERSION 3.26)
file(
    GLOB_RECURSE INCLUDES
    "${CMAKE_CURRENT_SOURCE_DIR}/*.hpp"
)

find_package(Clang)
include(FetchContent)
FetchContent_MakeAvailable(fmt)

add_library(tooling_CodegenCommon INTERFACE)
target_link_libraries(tooling_CodegenCommon INTERFACE fmt::fmt libclang)
target_include_directories(tooling_CodegenCommon INTERFACE ${LLVM_DIR})

add_executable(tooling_EnumCodegen EnumCodegen.cpp)
target_link_libraries(tooling_EnumCodegen PRIVATE tooling_CodegenCommon)

add_executable(tooling_SerializationCodegen SerializationCodegen.cpp)
target_link_libraries(tooling_SerializationCodegen PRIVATE tooling_CodegenCommon)

add_executable(tooling_ValidationCodegen ValidationCodegen.cpp)
target_link_libraries(tooling_ValidationCodegen PRIVATE tooling_CodegenCommon)

add_executable(tooling_TraitsCodegen TraitsCodegen.cpp)
target_link_libraries(tooling_TraitsCodegen PRIVATE tooling_CodegenCommon)

add_executable(tooling_BinaryEmbed BinaryEmbed.cpp)