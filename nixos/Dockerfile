
# This Dockerfile is expected to be used with the docker-compose.yml.
# See that file for more details on the container environment.
#
# Expected to be configured by a cmake submodule and placed in the CMAKE_CURRENT_BINARY_DIR.
# When running the container a `run.sh` script must also be present in CMAKE_CURRENT_BINARY_DIR to execute.
# It will most likely originally be a .in file to configure with variables to other scripts and directories.


FROM archlinux:latest

ARG CMAKE_CURRENT_BINARY_DIR

CMD $CMAKE_CURRENT_BINARY_DIR/run.sh

