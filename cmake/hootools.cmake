include(FetchContent)

message("Fetching hootools\n")

set(HOOTOOLS_FBX2GLTF_ENABLE ON CACHE BOOL "")
set(HOOTOOLS_RAYLIBTECH_ENABLE ON CACHE BOOL "")
set(HOOTOOLS_ODIN_ENABLE ON CACHE BOOL "")
set(HOOTOOLS_ODIN_USE_EXTERNAL_RAYLIB ON CACHE BOOL "")

FetchContent_Declare(hootools
		GIT_REPOSITORY git@github.com:KotzaBoss/hootools.git
		EXCLUDE_FROM_ALL
	)
FetchContent_MakeAvailable(hootools)
