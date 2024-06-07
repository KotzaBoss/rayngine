
find_program(DOCKER docker REQUIRED DOC "Bandaid the size of a whale to preprocess the Mini Space Pack.")

function (nixos_docker_run)
	cmake_parse_arguments(D "" "WORKING_DIRECTORY;CONFIGURE_SCRIPT" "" ${ARGN})

	if (D_KEYWORDS_MISSING_VALUES)
		m(FATAL_ERROR "Both WORKING_DIRECTORY and CONFIGURE_SCRIPT are required")
	endif()

	configure_file(${CMAKE_SOURCE_DIR}/nixos/docker-compose.yml.in ${CMAKE_CURRENT_BINARY_DIR}/docker-compose.yml)
	configure_file(${D_CONFIGURE_SCRIPT} ${CMAKE_CURRENT_BINARY_DIR}/run.sh FILE_PERMISSIONS OWNER_EXECUTE)

	m("Building docker image, this may take a few moments...")
	execute_process(
			WORKING_DIRECTORY ${RAYNGINE_MINI_SPACE_PACK_DIR}
			COMMAND ${DOCKER} compose build -q
		)

	m("Launching docker container to convert fbx to gltf")
	execute_process(
			WORKING_DIRECTORY ${RAYNGINE_MINI_SPACE_PACK_DIR}
			COMMAND ${DOCKER} compose up
		)

endfunction()

