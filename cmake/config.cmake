
# See bottom of file for variable postprocessing.
# tl;dr: The path variables are passed through string(CONFIGURE)


set(RAYNGINE_VERBOSE OFF CACHE BOOL "")


if (NOT CMAKE_BUILD_TYPE)
	message(WARNING "CMAKE_BUILD_TYPE was not set, defaulting to \"Debug\"")
	# Hack because cmake's default value for CMAKE_BUILD_TYPE is "" ...
	set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "" FORCE)
	set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release")
endif()
set(RAYNGINE_BUILD_TYPE ${CMAKE_BUILD_TYPE} CACHE INTERNAL "")


# Sanitizers
set(RAYNGINE_SANITIZE_MEMORY OFF CACHE STRING [[
Unfortunately the name of one of the "memory" sanitizers is "Memory sanitizer"...
Ignoring that, either "Memory" or "Address" sanitizer can be used not both.
See their "help" for details.

* address: https://github.com/google/sanitizers/wiki/AddressSanitizer
* memory: https://github.com/google/sanitizers/wiki/MemorySanitizer
]])
set_property(CACHE RAYNGINE_SANITIZE_MEMORY PROPERTY STRINGS OFF "address" "memory")

set(RAYNGINE_SANITIZE_THREAD OFF CACHE BOOL "https://github.com/google/sanitizers/wiki/ThreadSanitizerCppManual")


set(RAYNGINE_ODIN_COLLECTION "${PROJECT_SOURCE_DIR}/src" CACHE PATH "Where is the -collection:rayngine")


# Resources
set(RAYNGINE_RESOURCE_DIR "${CMAKE_BINARY_DIR}/res" CACHE PATH "")
set(RAYNGINE_MINI_SPACE_PACK_DIR "${RAYNGINE_RESOURCE_DIR}/Mini_space_pack" CACHE PATH "")


		# Postprocess cache

get_cmake_property(RAYNGINE_VARIABLES CACHE_VARIABLES)
list(FILTER RAYNGINE_VARIABLES INCLUDE REGEX "RAYNGINE_.*")

# Configure the variables of type FILEPATH and PATH to allow for
# cmake variables as input:
#
# 	/some/explicit/path			ok
# 	${CMAKE_BINARY_DIR}/some/path		ok
#	\${CMAKE_BINARY_DIR}/some/path		BAD, results in \/path/to/build/some/path
#
foreach(v IN LISTS RAYNGINE_VARIABLES)
	get_property(type CACHE ${v} PROPERTY TYPE)
	if (type MATCHES "PATH|FILEPATH")
		get_property(value CACHE ${v} PROPERTY VALUE)
		string(CONFIGURE ${value} value)
		set_property(CACHE ${v} PROPERTY VALUE ${value})
	endif()
endforeach()


		# Report

section("Config report")
foreach (v IN LISTS RAYNGINE_VARIABLES)
	message(STATUS "${v} -> ${${v}}")
endforeach()

