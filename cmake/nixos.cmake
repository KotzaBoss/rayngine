
# NOTE:
# 	This can be run as a script if necessary, see bottom of file.
#

cmake_host_system_information(RESULT distrib_name QUERY DISTRIB_NAME)
set(NIXOS $<BOOL:$<STREQUAL:${distrib_name},NixOS>>)

if (NIXOS AND NOT DEFINED ENV{_RAYNGINE_NIX_SHELL_ACTIVE})
	message(FATAL_ERROR
			"Before configuring cmake make sure to run:\n"
			"    nix develop ./nixos\n"
		)
endif()

find_program(DOCKER docker REQUIRED DOC "Bandaid the size of a whale to preprocess the Mini Space Pack.")

function (nixos_run docker_compose script working_directory)

	configure_file(${docker_compose} ${working_directory}/docker-compose.yml)

	configure_file(${script} ${working_directory}/run.sh FILE_PERMISSIONS WORLD_EXECUTE)

	message(STATUS "Building docker image, this may take a few moments...")
	execute_process(
			WORKING_DIRECTORY ${working_directory}
			COMMAND ${DOCKER} compose build -q
		)

	message(STATUS "Launching docker container to convert fbx to gltf")
	execute_process(
			WORKING_DIRECTORY ${working_directory}
			COMMAND ${DOCKER} compose up --abort-on-container-failure
			RESULT_VARIABLE result
			COMMAND_ERROR_IS_FATAL ANY
		)

endfunction()


		# Script Mode
		# Thanks: https://stackoverflow.com/questions/51427538/cmake-test-if-i-am-in-scripting-mode

if(CMAKE_SCRIPT_MODE_FILE AND NOT CMAKE_PARENT_LIST_FILE)
	# 0     1  2            3  4              5      6
	# cmake -P script.cmake -- docker_compose script working_directory
	if (NOT (CMAKE_ARGV4 AND CMAKE_ARGV5))
		message(FATAL_ERROR "Arguments expected, see nixos_run()")
	else()
		nixos_run(${CMAKE_ARGV4} ${CMAKE_ARGV5} ${CMAKE_ARGV6})
	endif()
endif()
