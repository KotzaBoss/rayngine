# Gather odin packages
file(GLOB files DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} "${CMAKE_CURRENT_SOURCE_DIR}/*")
foreach(f ${files})
	string(REGEX MATCH "src$" match ${f})
	if (NOT match AND IS_DIRECTORY ${f})
		cmake_path(GET f STEM pkg)
		list(APPEND pkgs ${pkg})
	endif()
endforeach()


# Individual tests: test_some_package
message(STATUS "Packages:")
foreach (pkg ${pkgs})
	message(STATUS "\t${CMAKE_CURRENT_SOURCE_DIR}/${pkg}")

	add_custom_target(${pkg}
			COMMAND ${CMAKE_COMMAND} -E copy_directory
				${CMAKE_CURRENT_SOURCE_DIR}/${pkg}
				${CMAKE_BINARY_DIR}/${pkg}
				COMMENT "Copy packages, use -collection:rayngine=$\{CMAKE_BINARY_DIR}"
		)

	add_custom_target(test_${pkg}
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			DEPENDS odin ${pkg}
			COMMAND ${ODIN} test
				${CMAKE_CURRENT_SOURCE_DIR}/${pkg}
				${ODIN_DEFINES}
		)
endforeach()


# Test all
set(tests ${pkgs})
list(TRANSFORM tests PREPEND test_)
add_custom_target(tests
		DEPENDS ${tests}
	)
