cmake_minimum_required(VERSION 3.27)

project(rayngine
        VERSION 0.0.1
        LANGUAGES C
    )

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

include(utils)

include(nixos)
if (NIXOS)	
	add_subdirectory(nixos)
endif()

include(kconfig)
section("This is a ${RAYNGINE_BUILD_TYPE} build")

set(CMAKE_BUILD_TYPE ${RAYNGINE_BUILD_TYPE})

if (RAYNGINE_VERBOSE)
	set(CMAKE_MESSAGE_LOG_LEVEL VERBOSE)
endif()

include(deps)
include(odin)

add_subdirectory(res)
add_subdirectory(src)
add_subdirectory(bin)
add_subdirectory(test)

include(help)
