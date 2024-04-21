cmake_minimum_required(VERSION 3.28)

project(rayngine
        VERSION 0.0.1
        LANGUAGES C
    )

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

include(utils)

include(kconfig)
set(CMAKE_BUILD_TYPE ${RAYNGINE_BUILD_TYPE})
if (RAYNGINE_VERBOSE)
	set(CMAKE_MESSAGE_LOG_LEVEL VERBOSE)
endif()

include(deps)
include(odin)

add_subdirectory(src)
add_subdirectory(bin)

section("Commands:")
message("cmake --build build -- rayngine")
message("cmake --build build -- rguilayout")
message("cmake --build build -- tests")
message("")
