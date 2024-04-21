cmake_minimum_required(VERSION 3.28)

project(rayngine
        VERSION 0.0.1
        LANGUAGES C
    )

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

include(kconfig)
set(CMAKE_BUILD_TYPE ${RAYNGINE_BUILD_TYPE})

include(deps)
include(odin)

add_subdirectory(src)
add_subdirectory(bin)

message("")
message(STATUS "\tCommands:")
message("")
message("cmake --build build -- rayngine")
message("cmake --build build -- rguilayout")
message("cmake --build build -- tests")
message("")
