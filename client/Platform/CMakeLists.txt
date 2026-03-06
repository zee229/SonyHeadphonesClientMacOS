cmake_minimum_required(VERSION 3.26)

add_library(Client_Platform INTERFACE)
target_link_libraries(
        Client_Platform
        INTERFACE
        mdr
        fmt::fmt
)

add_subdirectory(MacOS)
target_link_libraries(Client_Platform INTERFACE Client_PlatformMacOS)
