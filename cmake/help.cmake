#
# Include this last to prompt the user to run the help command
#

list(APPEND echo "${CMAKE_COMMAND}" -E echo :::)

add_custom_target(h
		COMMAND ${echo}
		COMMAND ${echo} "\tHelp:"
		COMMAND ${echo}
		COMMAND ${echo} "\t    cmake --build build -- <target>"
		COMMAND ${echo}
		COMMAND ${echo} "\tTargets:"
		COMMAND ${echo}
		COMMAND ${echo} "\t    h                    This help"
		COMMAND ${echo} "\t    rayngine             Rayngine binary"
		COMMAND ${echo} "\t    tests                Test everything"
		COMMAND ${echo} "\t    test_some_package    Test only `some_package`"
		COMMAND ${echo} "\t    rguilayout           Not ready yet"
		COMMAND ${echo}

		DEPENDS $<$<BOOL:${NIXOS}>:h_nixos>

		VERBATIM
	)

add_custom_target(h_nixos
		COMMAND ${echo}
		COMMAND ${echo} "\tI've detected that you are on NixOS. Before programming, run:"
		COMMAND ${echo}
		COMMAND ${echo} "\t    nix develop ./nixos"
		COMMAND ${echo}
		COMMAND ${echo} "\tto enter the development shell."
		COMMAND ${echo}

		VERBATIM
	)


m(WARNING
		"Make sure you run:"
		"\tcmake --build build -- h"
		"for information before hacking away."
	)
