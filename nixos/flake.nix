{
	description = "Flake for rayngine";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
	};

	outputs = { self, nixpkgs, ... }:
	let
		system = "x86_64-linux";
		pkgs = nixpkgs.legacyPackages.${system};
	in {
		devShells.x86_64-linux.default = pkgs.mkShell {

			# Test against this env variable to check if in a nix shell and
			# DO NOT MODIFY ANYWHERE.
			_RAYNGINE_NIX_SHELL_ACTIVE = true;

			packages = with pkgs; [
				pkg-config
				gdb

				# cmake
				cmake
				ninja

				# kconfig
				kconfig-frontends

				# odin
				llvm
				clang

				# raylib
				glfw
				libxkbcommon
				wayland
				libffi
				xorg.libX11
				xorg.libXrandr
				xorg.libXinerama
				xorg.libXcursor
				xorg.libXi
				libglvnd
			];

			LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [
				wayland
				libxkbcommon
				libglvnd
			];

			shellHook = ''
				clear
				echo
				echo "::: NixOS development environment for rayngine :::" | ${pkgs.lolcat}/bin/lolcat
				echo
			'';
		};
	};
		
}
