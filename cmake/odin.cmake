include(FetchContent)
include(CMakePrintHelpers)

# Fetch Odin
FetchContent_Declare(odin
		GIT_REPOSITORY https://github.com/odin-lang/Odin
        GIT_TAG master
		EXCLUDE_FROM_ALL
    )

message("")
message(STATUS "\tOdin")
message("")

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
		COMMAND ./build_odin.sh
		COMMENT "Building odin, this should be done once"
	)


# Prepare ODIN_DEFINES
foreach (v ${RAYNGINE_VARIABLES})
	set(key ${v})
	set(value ${${v}})
	if (${value} STREQUAL "y")
		list(APPEND ODIN_DEFINES "${key}=true")
	elseif (${value} STREQUAL "n")
		list(APPEND ODIN_DEFINES "${key}=false")
	else()
		list(APPEND ODIN_DEFINES "${key}=\"${value}\"")
	endif()
endforeach()
list(TRANSFORM ODIN_DEFINES PREPEND "-define:")


message(STATUS "Odin definitions:")
foreach (odin_define IN LISTS ODIN_DEFINES)
	message(STATUS "\t${odin_define}")
endforeach()

