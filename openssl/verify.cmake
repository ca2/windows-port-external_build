if(__REACTOS__)
    foreach(component IN ITEMS crypto ssl)
        execute_process(COMMAND "${CMAKE_OBJDUMP}" -p "${OPENSSL_INSTALL_DIR}/bin/lib${component}-3.dll"
            OUTPUT_VARIABLE imports COMMAND_ERROR_IS_FATAL ANY)
        string(TOLOWER "${imports}" lower_imports)
        if(lower_imports MATCHES "dll name: (api-ms-|ucrtbase|bcrypt|msys-|cygwin)")
            message(FATAL_ERROR "OpenSSL XP build imports a runtime unavailable on XP: lib${component}")
        endif()
        foreach(api IN ITEMS BCryptGenRandom GetTickCount64 InitOnceExecuteOnce InitializeSRWLock
                AcquireSRWLockExclusive AcquireSRWLockShared ReleaseSRWLockExclusive ReleaseSRWLockShared
                InitializeCriticalSectionEx GetSystemTimePreciseAsFileTime GetFileInformationByHandleEx
                CancelIoEx GetOverlappedResultEx)
            if(imports MATCHES "[ \t]${api}[\r\n]")
                message(FATAL_ERROR "OpenSSL XP build imports ${api}: lib${component}")
            endif()
        endforeach()
        file(WRITE "${OPENSSL_INSTALL_DIR}/lib${component}-imports.txt" "${imports}")
    endforeach()
endif()
if(OPENSSL_VERIFY)
    # This runs on the modern build host, not on XP. Save the evidence separately.
    set(ENV{PATH} "${OPENSSL_INSTALL_DIR}/bin;${compiler_directory};$ENV{PATH}")
    set(ENV{OPENSSL_CONF} "${OPENSSL_INSTALL_DIR}/ssl/openssl.cnf")
    set(ENV{OPENSSL_MODULES} "${OPENSSL_INSTALL_DIR}/lib/ossl-modules")
    set(ENV{OPENSSL_ENGINES} "${OPENSSL_INSTALL_DIR}/lib/engines-3")
    execute_process(COMMAND "${OPENSSL_INSTALL_DIR}/bin/openssl.exe" version -a
        OUTPUT_VARIABLE version_output COMMAND_ERROR_IS_FATAL ANY)
    execute_process(COMMAND "${OPENSSL_INSTALL_DIR}/bin/openssl.exe" rand -hex 32
        OUTPUT_VARIABLE random_output COMMAND_ERROR_IS_FATAL ANY)
    execute_process(COMMAND "${OPENSSL_INSTALL_DIR}/bin/openssl.exe" ciphers -s
        OUTPUT_VARIABLE cipher_output COMMAND_ERROR_IS_FATAL ANY)
    file(WRITE "${BINARY_DIR}/sha256-smoke.txt" "abc")
    execute_process(COMMAND "${OPENSSL_INSTALL_DIR}/bin/openssl.exe" dgst -sha256 "${BINARY_DIR}/sha256-smoke.txt"
        OUTPUT_VARIABLE digest_output COMMAND_ERROR_IS_FATAL ANY)
    if(NOT digest_output MATCHES "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        message(FATAL_ERROR "OpenSSL SHA256 known-answer test failed")
    endif()
    file(WRITE "${OPENSSL_INSTALL_DIR}/build-verification.txt"
        "${version_output}\nRandom generator smoke test:\n${random_output}\nTLS ciphers:\n${cipher_output}\nSHA256:\n${digest_output}")
endif()
file(WRITE "${OPENSSL_INSTALL_DIR}/build-profile.txt"
    "OpenSSL=${OPENSSL_VERSION}\nXP=${__REACTOS__}\nPointerBytes=${CMAKE_SIZEOF_VOID_P}\nConfiguration=${CMAKE_BUILD_TYPE}\nCompiler=${CMAKE_C_COMPILER}\n")
