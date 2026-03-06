# Sets MDR_PLATFORM_OS to MACOS. Only macOS is supported.
function(MDR_DetectPlatform)
    if(NOT APPLE OR NOT CMAKE_SYSTEM_NAME MATCHES ".*(Darwin|MacOS).*")
        message(FATAL_ERROR "Only macOS is supported")
    endif()
    set(MDR_PLATFORM_OS "MACOS" PARENT_SCOPE)
    message(STATUS "Detected Platform: MACOS")
endfunction()
