add_custom_target(rguilayout
		WORKING_DIRECTORY ${rguilayout_SOURCE_DIR}
		COMMAND ./rguilayout
		COMMENT "Launching rGuiLayout, see ${CMAKE_CURRENT_SOURCE_DIR}/README.md for more info"
	)


section("Preparing libraygui with gui_*.h files:")

file(GLOB guis RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "gui_*.h")
foreach (gui.h ${guis})
	# TODO: Confirm if we can have the glob equivalent so that we skip complicating with an extra regex step
	set(regex "gui_([a-zA-Z0-9]+).h")
	string(REGEX MATCH ${regex} match ${gui.h})
	if (NOT match)
		message(FATAL_ERROR "Pattern ${regex} does not match file ${gui.h}")
	else()
		message(STATUS "${gui.h}")
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
target_include_directories(raygui PRIVATE
		${CMAKE_CURRENT_SOURCE_DIR}
		${raylib_SOURCE_DIR}/src
		${raygui_SOURCE_DIR}/src
	)

