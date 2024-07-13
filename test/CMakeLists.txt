include(utils)

section("Test")

add_odin_tests(rayngine_tests ${CMAKE_SOURCE_DIR}/src
		COLLECTION rayngine
		EXTRA_ARGS ${RAYNGINE_ODIN_COLLECTION}
		SKIP ui ecs
	)

