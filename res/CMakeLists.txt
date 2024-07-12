section("Mini space pack")

cconfig(RAYNGINE_RESOURCE_DIR PATH ${CMAKE_CURRENT_BINARY_DIR} "")

message(STATUS "Extracting zip")

cconfig(RAYNGINE_MINI_SPACE_PACK_DIR PATH "${RAYNGINE_RESOURCE_DIR}/Mini_space_pack" "")
file(ARCHIVE_EXTRACT
		INPUT "${CMAKE_CURRENT_SOURCE_DIR}/Mini space pack.zip"
		DESTINATION "${RAYNGINE_MINI_SPACE_PACK_DIR}"
	)

# Cmake in script mode doesnt inherit the cache, so prepare the files from here`
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/mini_space_pack_fbx2gltf.sh.in ${CMAKE_CURRENT_BINARY_DIR}/run.sh)

if (NOT NIXOS)
	add_custom_target(res
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			COMMAND ./run.sh
			COMMENT "Preparing Mini space pack"
		)
else()
	configure_file(${hootools_SOURCE_DIR}/nixos/docker-compose.yml.in ${CMAKE_CURRENT_BINARY_DIR}/docker-compose.yml)
	add_custom_target(res
		COMMAND ${CMAKE_COMMAND} -P ${hootools_SOURCE_DIR}/nixos/nixos.cmake --
			${CMAKE_CURRENT_BINARY_DIR}/docker-compose.yml
			${CMAKE_CURRENT_BINARY_DIR}/run.sh
		COMMENT "Preparing Mini space pack for NixOS"
		)
endif()
