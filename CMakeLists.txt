cmake_minimum_required(VERSION 3.27)

project(rayngine
        VERSION 0.0.1
		LANGUAGES NONE	# Delay enabling C until hootools is prepared, see below `enable_language()`
    )

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

include(hootools)

# If we are in NixOS it can be clunky to bootstrap the project.
# So we get hootools first and when cmake builds it error with
# the suggestion to `nix develop` the hootools nixos flake and then continue.
enable_language(C)


include(utils)
include(config)
include(deps)

section("This is a ${RAYNGINE_BUILD_TYPE} build")

add_subdirectory(res)
add_subdirectory(src)
add_subdirectory(bin)
#add_subdirectory(test)

include(help)

feature_summary(WHAT ALL)

