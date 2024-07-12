

get_cache_variables(defs "RAYNGINE_.*")

add_odin_executable(rayngine ${CMAKE_CURRENT_SOURCE_DIR}
		EXTRA_DEFINES ${defs}
		EXTRA_ARGS
			-out:${CMAKE_CURRENT_BINARY_DIR}/rayngine
			-collection:rayngine=${CMAKE_SOURCE_DIR}/src
		DEPENDS odin res
		COMMENT "Building rayngine: ${CMAKE_CURRENT_BINARY_DIR}/rayngine"
	)


