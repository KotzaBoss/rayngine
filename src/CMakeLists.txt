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
foreach (pkg ${pkgs})
	# Copy packages to make odin import "rayngine:some_package" work
	file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/${pkg} DESTINATION ${CMAKE_BINARY_DIR})

	add_custom_target(test_${pkg}
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
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
