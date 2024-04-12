include(FetchContent)

set(FETCHCONTENT_QUIET OFF)

FetchContent_Declare(raylib
		GIT_REPOSITORY git@github.com:KotzaBoss/raylib.git
		GIT_TAG  clip-distance-variable
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

FetchContent_Declare(rguilayout
		URL https://github.com/raysan5/rguilayout/releases/download/4.0/rguilayout_v4.0_linux_x64.zip
		EXCLUDE_FROM_ALL
	)


message("")
message(STATUS "\traylib technologies")
message("")

FetchContent_MakeAvailable(raylib raygui rguilayout)


message("")
message(STATUS "\tglfw")
message("")

FetchContent_GetProperties(glfw)
if (NOT glfw_POPULATED)
	FetchContent_Populate(glfw)

	message(STATUS "Tweaking build options (GLFW_USE_WAYLAND, GLFW_BUILD_WAYLAND/X11)")
	unset(GLFW_USE_WAYLAND CACHE)
	set(GLFW_BUILD_WAYLAND ON)
	set(GLFW_BUILD_X11 ON)
endif()


# Report
message("")
message(STATUS "FetchContent report:")
foreach (r raylib raygui rguilayout glfw)
	message(STATUS "\t${r}:")
	message(STATUS "\t\t${${r}_SOURCE_DIR}")
	message(STATUS "\t\t${${r}_BINARY_DIR}")
endforeach()

