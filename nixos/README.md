# Why

As an example, using [`FBX2glTF`](https://github.com/godotengine/FBX2glTF) to do what the name suggests, is trivial. No matter your setup, simply get the tar file, extract and execute.

For nix it is not so simple because the program calls the FBX dynamic library which would not be a problem if that library was available as a nix package. Fixing the problem manually is [not exactly trivial](https://nix.dev/guides/faq#how-to-run-non-nix-executables) and i wanted something *now*. As such i took a day to make a simple docker setup to pretend we are on archlinux from time to time if needed.

Learning how to manually package such programs will be definitely educational but for the moment i don't want to be lost in the sauce.
# How

To use them correctly:
- Add the nixos cmake module
- Call the imported function:
	```cmake
	nixos_run(${CMAKE_CURRENT_SOURCE_DIR}/.../script.sh.in)
	```

To avoid headaches, make use of cmake's SOURCE/BINARY directory variables (as you should be doing for your project anyway) and the SOURCE/BINARY directories mirror each other.
^0f40a2

For internal details about the use of docker see [[#What]].
# What

This setup consists of two files, a [[Dockerfile]] and a [[docker-compose.yml.in]], which are meant to always be used together by a cmake module.

What the `nixos_run` function does is:
- Configure the `docker-compose.yml.in` into to the caller's `CMAKE_CURRENT_BINARY_DIR`
- Configure the `CONFIGURE_SCRIPT` into to the caller's `CMAKE_CURRENT_BINARY_DIR`
- Call `docker compose build` in the `WORKING_DIRECTORY`
- Call `docker compose up` in the `WORKING_DIRECTORY`

The "interesting" part of all that the configuration uses the callers `CMAKE_*` variables to setup the container's environment and more importantly the volume for rayngine's build directory.
When the container is up the `CMAKE_BINARY_DIR` will be mounted *as the same path* in the container. For example, both our host and the container will have the same, `/home/user/git/rayngine/build`path.

The reason the paths were kept the same is that the file configurations will *just work*™ with the cmake variables. Elaborating on how [[#^0f40a2|"to avoid headaches"]], assume this simplified setup:
```
my_project
	|- res
		|- script.sh.in
		|- some_assets.zip
	|- deps
```
If we make use of the cmake variables in our configuration:
```cmake
set(SOME_ASSET_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/some_assets)

file(EXTRACT
	${CMAKE_CURRENT_SOURCE_DIR}/some_assets.zip
	${SOME_ASSET_BUILD_DIR}
)

configure_file(
	${CMAKE_CURRENT_SOURCE_DIR}/script.sh.in
	${CMAKE_CURRENT_BINARY_DIR}/run.sh
)
```
Prepare our processing dependencies (arbitrarily in "deps"):
```cmake
FetchContent_Declare(some_tool ...)
FetchContent_MakeAvailable(some_tool)
# Note that some_tool_SOURCE_DIR is filled by FetchContent, see:
# https://cmake.org/cmake/help/latest/module/FetchContent.html
set(SOME_TOOL ${some_tool_SOURCE_DIR}/some_tool_executable)
```
Write our `script.sh.in`:
```sh
#!/bin/bash

pushd ${SOME_ASSET_BUILD_DIR}

for asset in *.asset; do
    ${SOME_TOOL} $asset
done

popd
```
After running cmake we will have:
```
my_project
	|- build
		|- res
			|- some_assets
				|- a.asset
				|- b.asset
			|- run.sh
		|- deps
	|- res
		|- script.sh.in
		|- some_assets.zip
	|- deps
```
Running the `run.sh` script will then *just work*™️.

You could argue that it is possible to circumvent the configuring of the script by making the convention that it is always dumped in the directory it should be doing work. For our example, we could just copy the script into the `SOME_ASSET_BUILD_DIR` and remove the `pushd`/`popd` since we are already in the directory of the assets.

That is true but i find my setup of configuring files and maintaining a build that strictly mirrors the source to be more *predictable*, *explicit*, and implicitely, *flexible*.
- *Predictable*: there are no surprises in the placement of files during configuration.
- *Explicit*: each "work unit" has to... explicitely define its configuration dependencies.
- *Flexible*: as a result of proper configuration, each "work unit" can operate from anywhere.

While the accidental flexibility can be considered a "happy little accident", the first two points give a promise of reduced mental load for future changes and bugs.