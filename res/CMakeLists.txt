section("Mini space pack")

cconfig(RAYNGINE_RESOURCE_DIR PATH ${CMAKE_CURRENT_BINARY_DIR} DOC "")

message(STATUS "Extracting zip")

cconfig(RAYNGINE_MINI_SPACE_PACK_DIR PATH "${RAYNGINE_RESOURCE_DIR}/Mini_space_pack" DOC "")
file(ARCHIVE_EXTRACT
		INPUT "${CMAKE_CURRENT_SOURCE_DIR}/Mini space pack.zip"
		DESTINATION "${RAYNGINE_MINI_SPACE_PACK_DIR}"
	)


if (NOT NIXOS)
	configure_file(${CMAKE_CURRENT_SOURCE_DIR}/mini_space_pack_fbx2gltf.sh.in ${CMAKE_CURRENT_BINARY_DIR}/run.sh)
	execute_process(
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			COMMAND ./run.sh
		)
else()
	nixos_run(res ${CMAKE_CURRENT_SOURCE_DIR}/mini_space_pack_fbx2gltf.sh.in)
endif()
