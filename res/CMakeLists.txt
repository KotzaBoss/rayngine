section("Mini space pack")

m("Extracting zip")
file(ARCHIVE_EXTRACT
		INPUT "${CMAKE_CURRENT_SOURCE_DIR}/Mini space pack.zip"
		DESTINATION "${RAYNGINE_MINI_SPACE_PACK_DIR}"
	)

m("Converting fbx to gltf")
file(GLOB fbxs "${RAYNGINE_MINI_SPACE_PACK_DIR}/*.fbx")

foreach (fbx IN LISTS fbxs)
	list(APPEND commands COMMAND ${FBX2GLTF} -b "${fbx}")
endforeach()

execute_process(
		WORKING_DIRECTORY "${RAYNGINE_MINI_SPACE_PACK_DIR}"
		${commands}
		OUTPUT_QUIET
	)

