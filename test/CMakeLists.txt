
# Testing is done after following odin's suggestion:
# > Suggestion: Make an .odin file that imports packages to test and use the `-all-packages` flag.


# .../src/some/package/some_code.odin
file(GLOB_RECURSE files "${CMAKE_SOURCE_DIR}/src/*/")
list(FILTER files INCLUDE REGEX ".*\.odin")


		# Individual tests: test_some_file

foreach (f IN LISTS files)		# .../src/some/package/some_file.odin
	cmake_path(GET f STEM name)	# some_file
	set(T test_${name})		# test_some_file

	add_custom_target(${T}
			DEPENDS odin
			COMMAND ${ODIN} test
				${f}
				${ODIN_ARGS}
				-file
		)
endforeach()


		# File for ALL tests

# some/package/some_code.odin
list(TRANSFORM files REPLACE ".*/src/" "")

# some/package
foreach(f IN LISTS files)
	cmake_path(GET f PARENT_PATH parent)
	list(APPEND pkgs ${parent})
endforeach()

list(REMOVE_DUPLICATES pkgs)


# import "rayngine:some/package
list(TRANSFORM pkgs PREPEND "import \"rayngine:")

# import "rayngine:some/package"
list(TRANSFORM pkgs APPEND "\"")

set(test_src ${pkgs})
list(PREPEND test_src "package test" "")
list(JOIN test_src "\n" test_src)
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/test.odin" ${test_src})

add_custom_target(tests
		DEPENDS odin
		COMMAND ${ODIN} test
			${CMAKE_CURRENT_BINARY_DIR}
			${ODIN_ARGS}
			-all-packages
	)
