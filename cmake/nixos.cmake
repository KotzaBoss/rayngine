
cmake_host_system_information(RESULT distrib_name QUERY DISTRIB_NAME)
set(NIXOS $<BOOL:$<STREQUAL:${distrib_name},NixOS>>)

if (NIXOS AND NOT DEFINED ENV{_RAYNGINE_NIX_SHELL_ACTIVE})
	message(FATAL_ERROR
			"Before configuring cmake make sure to run:\n"
			"    nix develop ./nixos\n"
		)
endif()
