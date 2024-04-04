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

FetchContent_Declare(rguilayout
		URL https://github.com/raysan5/rguilayout/releases/download/4.0/rguilayout_v4.0_linux_x64.zip
	)


message("")
message(STATUS "\traylib, raygui, rGuiLayout")
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


###################################################################


# Copy to make the imports work in the build directory
file(COPY_FILE raygui.odin ${CMAKE_CURRENT_BINARY_DIR}/raygui.odin)


# Prepare libraygui from gui_*.h files
file(GLOB guis RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "gui_*.h")
foreach (gui.h ${guis})
	# TODO: Confirm if we can have the glob equivalent so that we skip complicating with an extra regex step
	set(regex "gui_([a-zA-Z0-9]+).h")
	string(REGEX MATCH ${regex} match ${gui.h})
	if (NOT match)
		message(FATAL_ERROR "Pattern ${regex} does not match file ${gui.h}")
	endif()

	cmake_path(GET gui.h STEM gui)

	set(src ${CMAKE_CURRENT_BINARY_DIR}/${gui}.c)

	string(TOUPPER ${CMAKE_MATCH_1} define)

	string(APPEND gui_defines_includes
			"#define GUI_${define}_IMPLEMENTATION\n"
			"#include \"${gui.h}\"\n"
		)
endforeach()

configure_file(libraygui.c.in libraygui.c)

add_library(raygui STATIC libraygui.c $<TARGET_OBJECTS:raylib> $<TARGET_OBJECTS:glfw>)
target_include_directories(raygui PRIVATE ${CMAKE_CURRENT_SOURCE_DIR} ${raylib_SOURCE_DIR}/src ${raygui_SOURCE_DIR}/src)


add_custom_target(rguilayout
		WORKING_DIRECTORY ${rguilayout_SOURCE_DIR}
		COMMAND ./rguilayout
		COMMENT "Launching rGuiLayout, see ${CMAKE_CURRENT_SOURCE_DIR}/README.md for more info"
	)

