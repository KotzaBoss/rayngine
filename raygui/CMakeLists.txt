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
	file(WRITE ${src}
			"#define RAYGUI_IMPLEMENTATION\n"
			"#include <raygui.h>\n"
			"#define GUI_${define}_IMPLEMENTATION\n"
			"#include \"${gui.h}\"\n"
		)

	add_library(${gui} STATIC ${src} $<TARGET_OBJECTS:raylib> $<TARGET_OBJECTS:glfw>)
	target_include_directories(${gui}
			PUBLIC
				${CMAKE_CURRENT_SOURCE_DIR}
				${raylib_SOURCE_DIR}/src
				${raygui_SOURCE_DIR}/src
		)

endforeach()
