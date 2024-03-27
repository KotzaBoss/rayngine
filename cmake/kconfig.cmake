# This module should be included as high as possible in the main CMakeList.txt
# as it populates variables RAYNGINE_* to be used by the project.

include(CMakePrintHelpers)

find_program(KCONFIG kconfig REQUIRED)


add_custom_target(menuconfig
        WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
		COMMAND CONFIG_=RAYNGINE_ kconfig-mconf ${PROJECT_SOURCE_DIR}/Kconfig
        COMMAND cmake -G${CMAKE_GENERATOR} --fresh .
        USES_TERMINAL
    )

add_custom_target(catconfig
		WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
		COMMAND cmake -E cat .config
	)


set(.config ${PROJECT_BINARY_DIR}/.config)
if (NOT EXISTS ${.config})
	file(COPY_FILE ${PROJECT_SOURCE_DIR}/defconfig ${.config})
endif()


# Parse .config and set CMake variables
file(STRINGS ${.config} config)
foreach (line IN LISTS config)
	if (NOT line MATCHES "(RAYNGINE_[A-Z_]+)=(.*)")
        continue()
    endif()

    set(key ${CMAKE_MATCH_1})
    set(value "${CMAKE_MATCH_2}")

    # Ignore double quotes if any
    if (${value} MATCHES "^\"(.*)\"$")
		set(type STRING)
		set(value ${CMAKE_MATCH_1})
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
	set(${key} ${value} CACHE ${type} "")

endforeach()

# Collect all config variables
get_cmake_property(RAYNGINE_VARIABLES VARIABLES)
list(FILTER RAYNGINE_VARIABLES INCLUDE REGEX "RAYNGINE_.*")


# Show results
message("")
message(STATUS "\tKconfig results")
message("")
foreach (v IN LISTS RAYNGINE_VARIABLES)
	cmake_print_variables(${v})
endforeach()


