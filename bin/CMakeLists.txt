add_custom_target(rayngine
		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
		COMMAND ${ODIN} build . -out:${CMAKE_CURRENT_BINARY_DIR}/rayngine ${ODIN_DEFINES}
		DEPENDS odin
	)


