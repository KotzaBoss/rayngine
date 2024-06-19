section("Mini space pack")

message(STATUS "Extracting zip")
file(ARCHIVE_EXTRACT
		INPUT "${CMAKE_CURRENT_SOURCE_DIR}/Mini space pack.zip"
		DESTINATION "${RAYNGINE_MINI_SPACE_PACK_DIR}"
	)

if (NOT NIXOS)
	configure_file(${CMAKE_CURRENT_SOURCE_DIR}/mini_space_pack_fbx2gltf.sh.in ${CMAKE_CURRENT_BINARY_DIR}/run.sh)
	add_custom_target(res
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			COMMAND ./run.sh
			COMMENT "Preparing Mini space pack"
		)
else()
	# Cmake in script mode doesnt inherit the cache, so prepare the files from here
	configure_file(${CMAKE_CURRENT_SOURCE_DIR}/mini_space_pack_fbx2gltf.sh.in ${CMAKE_CURRENT_BINARY_DIR}/mini_space_pack_fbx2gltf.sh)
	configure_file(${CMAKE_SOURCE_DIR}/nixos/docker-compose.yml.in ${CMAKE_CURRENT_BINARY_DIR}/docker-compose.yml)
	add_custom_target(res
		COMMAND ${CMAKE_COMMAND} -P ${CMAKE_SOURCE_DIR}/cmake/nixos.cmake --
			${CMAKE_CURRENT_BINARY_DIR}/docker-compose.yml
			${CMAKE_CURRENT_BINARY_DIR}/mini_space_pack_fbx2gltf.sh
		COMMENT "Preparing Mini space pack"
		)
endif()
