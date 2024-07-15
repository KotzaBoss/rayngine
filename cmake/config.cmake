include(utils)

# See bottom of file for variable postprocessing.
# tl;dr: The path variables are passed through string(CONFIGURE)

cconfig(RAYNGINE_VERBOSE BOOL OFF DOC "")

if (NOT CMAKE_BUILD_TYPE)
	message(WARNING "CMAKE_BUILD_TYPE was not set, defaulting to \"Debug\"")
	# Hack because cmake's default value for CMAKE_BUILD_TYPE is "" ...
	set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "" FORCE)
	set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release")
endif()
cconfig(RAYNGINE_BUILD_TYPE INTERNAL ${CMAKE_BUILD_TYPE} DOC "")


# Resources
cconfig(RAYNGINE_RESOURCE_DIR PATH "${CMAKE_BINARY_DIR}/res" DOC "")
cconfig(RAYNGINE_MINI_SPACE_PACK_DIR PATH "${RAYNGINE_RESOURCE_DIR}/Mini_space_pack" DOC "")

