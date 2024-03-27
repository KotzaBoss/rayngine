cmake_minimum_required(VERSION 3.28)

project(rayngine
        VERSION 0.0.1
        LANGUAGES CXX
    )

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

include(kconfig)
set(CMAKE_BUILD_TYPE ${RAYNGINE_BUILD_TYPE})

include(odin)
message(STATUS "Odin executable: ${ODIN}")

add_subdirectory(bin)

