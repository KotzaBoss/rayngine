include(CMakePrintHelpers)

# Fetch Odin
FetchContent_Declare(odin
		GIT_REPOSITORY https://github.com/KotzaBoss/Odin
		GIT_TAG master
		EXCLUDE_FROM_ALL
    )

section("Odin")

FetchContent_MakeAvailable(odin)

message(STATUS "Source dir: ${odin_SOURCE_DIR}")

# Prepare odin executable
set(ODIN ${odin_SOURCE_DIR}/odin CACHE PATH "Odin executable path")
message(STATUS "Executable: ${ODIN}")

# Only way i found to make sure odin is compiled once.
# Other targets should `DEPEND odin`
add_custom_target(odin DEPENDS ${ODIN})
add_custom_command(
		WORKING_DIRECTORY ${odin_SOURCE_DIR}
		OUTPUT ${ODIN}
		DEPENDS raylib
		COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_LINKER_FILE:raylib>
			${odin_SOURCE_DIR}/vendor/raylib/linux
		COMMAND ./build_odin.sh
		VERBATIM
		COMMENT "Building odin, this should be done once"
	)


# Odin arguments

		# ODIN_DEFINES

foreach (v IN LISTS RAYNGINE_VARIABLES)
	get_property(type CACHE ${v} PROPERTY TYPE)
	if (type STREQUAL BOOL)
		if (value)
			list(APPEND ODIN_DEFINES "${v}=true")
		else()
			list(APPEND ODIN_DEFINES "${v}=false")
		endif()
	else()
		get_property(value CACHE ${v} PROPERTY VALUE)
		list(APPEND ODIN_DEFINES "${v}=\"${value}\"")
	endif()
endforeach()

list(TRANSFORM ODIN_DEFINES PREPEND "-define:")


		# ODIN_FLAGS

if (RAYNGINE_ODIN_COLLECTION)
	list(APPEND ODIN_FLAGS "-collection:rayngine=${RAYNGINE_ODIN_COLLECTION}")
endif()

if (RAYNGINE_BUILD_TYPE STREQUAL "Debug")
	list(APPEND ODIN_FLAGS "-debug")
endif()


# Sanatizers
if (RAYNGINE_SANITIZE_MEMORY)
	list(APPEND ODIN_FLAGS "-sanitize:${RAYNGINE_SANITIZE_MEMORY}")
endif()

if (RAYNGINE_SANITIZE_THREAD)
	list(APPEND ODIN_FLAGS "-sanitize:thread")
endif()


		# ODIN_ARGS

set(ODIN_ARGS ${ODIN_DEFINES} ${ODIN_FLAGS})


section("Odin arguments")
foreach (a IN LISTS ODIN_ARGS)
	message(STATUS "${a}")
endforeach()

