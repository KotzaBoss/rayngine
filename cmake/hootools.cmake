include(FetchContent)

message("Fetching hootools\n")

FetchContent_Declare(hootools
		GIT_REPOSITORY git@github.com:KotzaBoss/hootools.git
		EXCLUDE_FROM_ALL
	)
FetchContent_MakeAvailable(hootools)
