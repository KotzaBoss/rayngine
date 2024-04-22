cmake_minimum_required(VERSION 3.28)

project(rayngine
        VERSION 0.0.1
        LANGUAGES C
    )

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

include(utils)

include(kconfig)
section("This is a ${RAYNGINE_BUILD_TYPE} build")

set(CMAKE_BUILD_TYPE ${RAYNGINE_BUILD_TYPE})

if (RAYNGINE_VERBOSE)
	set(CMAKE_MESSAGE_LOG_LEVEL VERBOSE)
endif()

include(deps)
include(odin)

add_subdirectory(src)
add_subdirectory(bin)

section("Commands")
m(NOTICE "cmake --build build -- rayngine")
m(NOTICE "cmake --build build -- tests")
m(NOTICE "cmake --build build -- test_some_package")
m(NOTICE "cmake --build build -- rguilayout")
m(NOTICE)
