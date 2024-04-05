add_custom_target(rayngine
	COMMAND cmake -E copy ${CMAKE_CURRENT_SOURCE_DIR}/rayngine.odin ${CMAKE_CURRENT_BINARY_DIR}
		COMMAND ${ODIN} build
			${CMAKE_CURRENT_BINARY_DIR}
			-out:${CMAKE_CURRENT_BINARY_DIR}/rayngine
			-collection:rayngine=${PROJECT_BINARY_DIR}
			$<$<BOOL:${RAYNGINE_BUILD_DEBUG}>:-debug>
			${ODIN_DEFINES}
		DEPENDS odin raygui
		COMMENT "Building rayngine: ${CMAKE_CURRENT_BINARY_DIR}/rayngine"
	)

