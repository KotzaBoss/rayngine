include(FetchContent)


FetchContent_Declare(raylib
		GIT_REPOSITORY https://github.com/raysan5/raylib.git
		GIT_TAG  5.0
		EXCLUDE_FROM_ALL
	)

FetchContent_Declare(raygui
		GIT_REPOSITORY https://github.com/raysan5/raygui.git
		EXCLUDE_FROM_ALL
	)

FetchContent_Declare(glfw
		GIT_REPOSITORY https://github.com/glfw/glfw.git
		EXCLUDE_FROM_ALL
	)


message("")
message("\traylib/raygui")
message("")

FetchContent_MakeAvailable(raylib raygui)


message("")
message(STATUS "\tglfw")
message("")

FetchContent_GetProperties(glfw)
if (NOT glfw_POPULATED)
	FetchContent_Populate(glfw)

	# To fix an error about GLFW_USE_WAYLAND
	unset(GLFW_USE_WAYLAND CACHE)
	set(GLFW_BUILD_WAYLAND ON)
	set(GLFW_BUILD_X11 ON)
endif()


# Report
message(STATUS "")
foreach (r raylib raygui glfw)
	message(STATUS "${r}:")
	message(STATUS "\t${${r}_SOURCE_DIR}")
	message(STATUS "\t${${r}_BINARY_DIR}")
endforeach()

