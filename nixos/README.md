# Why

As an example, using [`FBX2glTF`](https://github.com/godotengine/FBX2glTF) , to do what the name suggests, is trivial. No matter your setup, simply get the tar file, extract and execute.
For nix it is not so simple because the program calls the FBX dynamic library which would not be a problem if that library was available as a nix package. Fixing the problem manually is [not exactly trivial](https://nix.dev/guides/faq#how-to-run-non-nix-executables) and i wanted something *now*. As such i took a day to make a simple docker setup to pretend we are on archlinux from time to time if needed.
Learning how to manually package such programs will be definitely educational but for the moment i don't want to be lost in the sauce.
# How

To use them correctly simply call the cmake function:
```cmake
nixos_docker_run(
		WORKING_DIRECTORY ${some_work_dir}
		CONFIGURE_SCRIPT ${my_run_script.in}
)
```

To avoid headaches, make sure that all your paths are absolute and make use of cmake's SOURCE/BINARY directory variables (as you should be doing for your project anyway). ^0f40a2

For internal details about the use of docker see [[#What]].
# What

This setup consists of two files meant to always be used together by a cmake module:
- [[Dockerfile]]
- [[docker-compose.yml.in]]

What the `nixos_docker_run` functions does is:
- Configure the `docker-compose.yml.in` into to the caller's `CMAKE_CURRENT_BINARY_DIR`
- Configure the `CONFIGURE_SCRIPT` into to the caller's `CMAKE_CURRENT_BINARY_DIR`
- Call `docker compose build` in the `WORKING_DIRECTORY`
- Call `docker compose up` in the `WORKING_DIRECTORY`

The "interesting" part of all that is the configuration uses the callers `CMAKE_*` variables to setup the container's environment and more importantly the volume for rayngine's build dir.
When the container is up the `CMAKE_BINARY_DIR` will be mounted *as the same path* in the container. Both our host and the container will have the same, example, `/home/user/git/rayngine/build`path.

The reason the paths were kept the same is that the file configurations *will just work*™ with the cmake variables. Elaborating on how [[#^0f40a2|"to avoid headaches"]], assume this simplified setup:
```
my_project
	|--- res
			|--- script.sh.in
			|--- some_assets.zip
```
If we make use of the cmake variables in our configuration:
```
set(SOME_ASSET_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/some_assets)

file(EXTRACT ${CMAKE_CURRENT_SOURCE_DIR}/some_assets.zip ${SOME_ASSET_BUILD_DIR})
```
After running cmake we will have:
```
my_project
	|--- build
		|--- res
			|--- run.sh
			|--- some_assets
	|--- res
			|--- script.sh.in
			|--- some_assets.zip
```
Then a script:
```sh
#!/bin/bash

pushd ${SOME_ASSET_BUILD_DIR}

for asset in *.asset; do
    some_preprocessing $asset
done

popd
```
Can be configured and will *just work*™️ because our docker path mirrors our host's.
