# This module should be included as high as possible in the main CMakeList.txt
# as it populates variables RAYNGINE_* to be used by the project.

include(CMakePrintHelpers)

find_program(KCONFIG kconfig REQUIRED)
set(KCONFIG_FILE "${PROJECT_SOURCE_DIR}/Kconfig")
set(CONFIG_ RAYNGINE_)
set(.config ${PROJECT_BINARY_DIR}/.config)

add_custom_target(menuconfig
        WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
		COMMAND CONFIG_=${CONFIG_} ${KCONFIG} mconf ${KCONFIG_FILE}
		COMMAND cmake -G${CMAKE_GENERATOR} --fresh .
		USES_TERMINAL
    )

add_custom_target(catconfig COMMAND cmake -E cat ${.config})


# Check if .config exists or we changed Kconfig
set(RAYNGINE_KCONFIG_HASH_TYPE MD5 CACHE STRING "Hash type for Kconfig file")
file(${RAYNGINE_KCONFIG_HASH_TYPE} ${KCONFIG_FILE} kconfig_file_hash)

set(RAYNGINE_KCONFIG_HASH ${kconfig_file_hash} CACHE STRING "Hash of the Kconfig file")

if (NOT EXISTS ${.config})
	set(must_generate_default_config TRUE)
elseif (NOT $CACHE{RAYNGINE_KCONFIG_HASH} STREQUAL kconfig_file_hash)
	set(must_generate_default_config TRUE)
	file(REMOVE ${.config})
	set(RAYNGINE_KCONFIG_HASH ${kconfig_file_hash} CACHE STRING "Hash of the Kconfig file" FORCE)
endif()

if (must_generate_default_config)
	section("Generating default .config")

	set(ENV{CONFIG_} ${CONFIG_})
	execute_process(
			COMMAND ${KCONFIG} conf "${PROJECT_SOURCE_DIR}/Kconfig" --alldefconfig
			WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
			OUTPUT_QUIET
			COMMAND_ERROR_IS_FATAL ANY
		)
endif()


# Parse .config and set CMake variables
file(STRINGS ${.config} config)
if (CMAKE_VERSION VERSION_GREATER_EQUAL 3.29)
	message(DEPRECATION
			"Refactor the Kconfig regex parsing to be included in the file command."
			"Since version 3.29 this will populate the CMAKE_MATCH_* variables\n"
			"file(STRINGS ... REGEX \"...\")\n"
		)
endif()

foreach (line IN LISTS config)
	if (NOT line MATCHES "(RAYNGINE_[A-Z_]+)=(.*)")
		continue()
	endif()

    set(key ${CMAKE_MATCH_1})
    set(value "${CMAKE_MATCH_2}")

    # Ignore double quotes if any
    if (${value} MATCHES "^\"(.*)\"$")
		set(type STRING)
		string(CONFIGURE ${CMAKE_MATCH_1} value)
	elseif (${value} MATCHES "y|n")
		set(type BOOL)
	else()
		message(FATAL_ERROR "Value (${value}) of key (${key}) has unexpected type")
	endif()

	# Commented to remember edge case
	# Take care of any edges
	#if (${key} STREQUAL RAYNGINE_COMPILER_FLAGS_OTHER AND value)
	#if 	# Listify flags to be used safely with add_compile_options
	#if 	string(REPLACE " " ";" value ${value})
	#if endif()

	# TODO: Perhaps read any help and add it as a docstring?
	set(${key} ${value} CACHE ${type} "" FORCE)

endforeach()

# Collect all config variables
get_cmake_property(RAYNGINE_VARIABLES CACHE_VARIABLES)
list(FILTER RAYNGINE_VARIABLES INCLUDE REGEX "RAYNGINE_.*")


# Show results
section("Kconfig results")
foreach (v IN LISTS RAYNGINE_VARIABLES)
	cmake_print_variables(${v})
endforeach()


