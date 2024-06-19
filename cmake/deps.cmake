include(FetchContent)

FetchContent_Declare(raylib
		GIT_REPOSITORY https://github.com/raysan5/raylib.git
		GIT_TAG  master
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

FetchContent_Declare(fbx2gltf
		URL https://github.com/godotengine/FBX2glTF/releases/download/v0.13.1/FBX2glTF-linux-x86_64.zip
		EXCLUDE_FROM_ALL
	)


section("raylib technologies")

FetchContent_MakeAvailable(raylib raygui rguilayout)


section("fbx2gltf")

FetchContent_MakeAvailable(fbx2gltf)
set(FBX2GLTF ${fbx2gltf_SOURCE_DIR}/FBX2glTF-linux-x86_64)

message(STATUS "FBX2glTF executable: ${FBX2GLTF}")


section("glfw")

FetchContent_GetProperties(glfw)
if (NOT glfw_POPULATED)
	FetchContent_Populate(glfw)

	message(STATUS "Tweaking build options (GLFW_USE_WAYLAND, GLFW_BUILD_WAYLAND/X11)")
	unset(GLFW_USE_WAYLAND CACHE)
	set(GLFW_BUILD_WAYLAND ON)
	set(GLFW_BUILD_X11 ON)
endif()


# Report
section("FetchContent report")
message(STATUS "Root directory: ${FETCHCONTENT_BASE_DIR}")

