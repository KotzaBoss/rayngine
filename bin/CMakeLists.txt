

get_cache_variables(defs "RAYNGINE_.*")

add_odin_executable(rayngine ${CMAKE_CURRENT_SOURCE_DIR}
		EXTRA_DEFINES ${defs} HOOTOOLS_ON_WAYLAND
		EXTRA_ARGS
			-out:${CMAKE_CURRENT_BINARY_DIR}/rayngine
			${RAYNGINE_ODIN_COLLECTION}
		DEPENDS odin
		COMMENT "Building rayngine: ${CMAKE_CURRENT_BINARY_DIR}/rayngine"
	)


