cmake_minimum_required(VERSION 3.24)
project(cefclient_external NONE)
include(ExternalProject)

if(__REACTOS__)
    add_custom_target(cefclient_build
        COMMAND "${CMAKE_COMMAND}" -E echo "Skipping CEF: the prebuilt SDK does not support XP/ReactOS")
    return()
endif()

enable_language(C)
if(NOT WIN32 OR NOT MSVC OR CMAKE_CONFIGURATION_TYPES)
    message(FATAL_ERROR "CEF requires Windows MSVC and a single-configuration generator")
endif()
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "CEF SDK configuration" FORCE)
endif()
if(NOT CMAKE_BUILD_TYPE MATCHES "^(Debug|Release)$")
    message(FATAL_ERROR "CEF supplies Debug and Release SDKs")
endif()
if(CMAKE_C_COMPILER_ARCHITECTURE_ID STREQUAL "ARM64")
    set(architecture ARM64)
elseif(CMAKE_C_COMPILER_ARCHITECTURE_ID STREQUAL "x64")
    set(architecture x64)
else()
    message(FATAL_ERROR "CEF supplies Windows x64 and ARM64 SDKs")
endif()

get_filename_component(operating_system "${CMAKE_CURRENT_LIST_DIR}/../../../../operating_system" ABSOLUTE)
set(CEF_STORAGE_ROOT "${operating_system}/storage-windows" CACHE PATH "Shared Windows artifact storage")
set(CEF_CACHE_ROOT "${operating_system}/external_build/cef" CACHE PATH "Verified SDK and wrapper cache")
set(CEF_SDK_ROOT "" CACHE PATH "Use an already extracted, version-matched CEF SDK")
set(CEF_PLATFORM_TOOLSET v145 CACHE STRING "Visual Studio toolset for the CEF wrapper")
set(CEFCLIENT_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE PATH "Local CEF installer source")

find_program(POWERSHELL_EXECUTABLE NAMES powershell.exe REQUIRED)
set(install_root "${CMAKE_CURRENT_BINARY_DIR}/install")
set(sdk "${install_root}/${architecture}/${CMAKE_BUILD_TYPE}")
set(storage "${CEF_STORAGE_ROOT}/${architecture}/${CMAKE_BUILD_TYPE}")
set(sdk_option "")
if(CEF_SDK_ROOT)
    set(sdk_option -SdkRoot "${CEF_SDK_ROOT}")
endif()

file(MAKE_DIRECTORY "${sdk}/include")
add_library(libcef SHARED IMPORTED GLOBAL)
set_target_properties(libcef PROPERTIES
    IMPORTED_IMPLIB "${sdk}/library/libcef.lib"
    IMPORTED_LOCATION "${sdk}/binary/libcef.dll"
    INTERFACE_INCLUDE_DIRECTORIES "${sdk}")
add_library(libcef_dll_wrapper STATIC IMPORTED GLOBAL)
set_target_properties(libcef_dll_wrapper PROPERTIES
    IMPORTED_LOCATION "${sdk}/library/libcef_dll_wrapper.lib"
    INTERFACE_LINK_LIBRARIES libcef)

# The installer manages the verified redistributable cache and builds the wrapper.
ExternalProject_Add(cefclient_build SOURCE_DIR "${CEFCLIENT_SOURCE_DIR}"
    DOWNLOAD_COMMAND "" CONFIGURE_COMMAND "" BUILD_COMMAND "" INSTALL_COMMAND "")
ExternalProject_Add_Step(cefclient_build deploy_sdk
    COMMAND "${POWERSHELL_EXECUTABLE}" -NoProfile -ExecutionPolicy Bypass
        -File "${CMAKE_CURRENT_LIST_DIR}/setup.ps1"
        -Configuration "${CMAKE_BUILD_TYPE}" -Architecture "${architecture}"
        -StorageRoot "${install_root}" -ExternalBuildRoot "${CEF_CACHE_ROOT}"
        -CMakeExecutable "${CMAKE_COMMAND}" -PlatformToolset "${CEF_PLATFORM_TOOLSET}"
        ${sdk_option} -BuildWrapper
    COMMAND "${CMAKE_COMMAND}" "-DCEF_SDK=${sdk}" "-DCEF_STORAGE=${storage}"
        -P "${CMAKE_CURRENT_LIST_DIR}/publish.cmake"
    DEPENDEES install ALWAYS TRUE
    BYPRODUCTS "${sdk}/library/libcef.lib" "${sdk}/binary/libcef.dll"
        "${sdk}/library/libcef_dll_wrapper.lib"
    COMMENT "Installing the prebuilt CEF SDK and its C++ wrapper")
add_dependencies(libcef cefclient_build)
add_dependencies(libcef_dll_wrapper cefclient_build)
