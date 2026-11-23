function(external_build_stage_headers target install_dir)
    if(DEFINED EXTERNAL_BUILD_HEADER_STORAGE_ROOT)
        set(storage_root "${EXTERNAL_BUILD_HEADER_STORAGE_ROOT}")
    else()
        # Generated build drivers can live outside the consuming checkout.
        get_filename_component(storage_root
            "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../../operating_system/storage-windows" ABSOLUTE)
    endif()

    if(CMAKE_C_COMPILER_ARCHITECTURE_ID STREQUAL "ARM64")
        set(architecture arm64)
    elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(architecture x64)
    else()
        set(architecture Win32)
    endif()

    ExternalProject_Add_Step(${target} stage_headers
        COMMAND "${CMAKE_COMMAND}"
            "-DSDK_INCLUDE_DIR=${install_dir}/include"
            "-DSTORAGE_INCLUDE_DIR=${storage_root}/${architecture}/${CMAKE_BUILD_TYPE}/include"
            -P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/merge-headers.cmake"
        DEPENDEES install
        ALWAYS TRUE
        COMMENT "Staging installed headers for ${target}")
endfunction()
