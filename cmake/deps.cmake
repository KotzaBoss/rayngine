include(FetchContent)

if (RAYNGINE_VERBOSE)
	set(FETCHCONTENT_QUIET OFF)
endif()

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


section("raylib technologies")

FetchContent_MakeAvailable(raylib raygui rguilayout)


section("glfw")

FetchContent_GetProperties(glfw)
if (NOT glfw_POPULATED)
	FetchContent_Populate(glfw)

	m("Tweaking build options (GLFW_USE_WAYLAND, GLFW_BUILD_WAYLAND/X11)")
	unset(GLFW_USE_WAYLAND CACHE)
	set(GLFW_BUILD_WAYLAND ON)
	set(GLFW_BUILD_X11 ON)
endif()


# Report
section("FetchContent report")
m("Root directory: ${FETCHCONTENT_BASE_DIR}")

