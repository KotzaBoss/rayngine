
cmake_host_system_information(RESULT distrib_name QUERY DISTRIB_NAME)
if (distrib_name STREQUAL NixOS)
	set(NIXOS ON)
endif()
