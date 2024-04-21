add_subdirectory(raygui)


file(GLOB pkgs RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "${CMAKE_CURRENT_SOURCE_DIR}/*")
list(REMOVE_ITEM pkgs CMakeLists.txt)

if (RAYNGINE_VERBOSE)
	message(STATUS "Packages: ${pkgs}")
endif()


# Individual tests: test_some_package
foreach (pkg ${pkgs})
	set(T test_${pkg})
	list(APPEND tests ${T})
	add_custom_target(${T}
			DEPENDS odin
			COMMAND ${ODIN} test
				${CMAKE_CURRENT_SOURCE_DIR}/${pkg}
				${ODIN_ARGS}
		)
endforeach()


# Test all
add_custom_target(tests DEPENDS ${tests})
