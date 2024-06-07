
find_program(DOCKER docker REQUIRED DOC "Bandaid the size of a whale to preprocess the Mini Space Pack.")

# It is recommended to keep the structure of the build tree the same as that of the source's.
# As such, CONFIGURE_FILE should be ${CMAKE_CURRENT_BINARY_DIR}/path/to/script.sh.in
function (nixos_run script)

	configure_file(${CMAKE_SOURCE_DIR}/nixos/docker-compose.yml.in ${CMAKE_CURRENT_BINARY_DIR}/docker-compose.yml)

	configure_file(${script} ${CMAKE_CURRENT_BINARY_DIR}/run.sh FILE_PERMISSIONS OWNER_EXECUTE)

	m("Building docker image, this may take a few moments...")
	execute_process(
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			COMMAND ${DOCKER} compose build -q
		)

	m("Launching docker container to convert fbx to gltf")
	execute_process(
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			COMMAND ${DOCKER} compose up
		)

endfunction()

