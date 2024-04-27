
add_custom_target(rayngine
		COMMAND ${ODIN} build
			${CMAKE_CURRENT_SOURCE_DIR}
			-out:${CMAKE_CURRENT_BINARY_DIR}/rayngine
			${ODIN_ARGS}
		DEPENDS odin
		COMMENT "Building rayngine: ${CMAKE_CURRENT_BINARY_DIR}/rayngine"
	)

