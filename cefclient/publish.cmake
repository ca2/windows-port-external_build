foreach(directory IN ITEMS binary library include)
    file(COPY "${CEF_SDK}/${directory}/" DESTINATION "${CEF_STORAGE}/${directory}")
endforeach()
