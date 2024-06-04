# rayngine

> [!tip] When in doubt:
> ```shell
> cmake --build build -- h
> ```
## Getting started

See [[#NixOS]] for details about that particular distribution.

```shell
git clone https://github.com/KotzaBoss/rayngine.git
cd rayngine
cmake -Bbuild
cmake --build build -- rayngine && ./build/bin/rayngine
```
## NixOS

> [!WARNING] **EXPERIMENTAL**
> I can build rayngine successfully but converting the fbx models to gltf does not work because the `fbx2gltf` program dynamically calls an sdk and in NixOS that does not work without manual intervention which is documented [here](https://nix.dev/guides/faq#how-to-run-non-nix-executables)

Given it's unique design, you need to setup a shell before working on rayngine. It *should* be as simple as:

```bash
nix develop ./nixos
```

You can then continue hacking normally.

Do not forget the resources available if there is a nix related problem:
- [Manual](https://nixos.org/manual/nixos/stable/)
- [Packages](https://search.nixos.org/packages?)
- `man configuration.nix`
- [`nix-index`](https://github.com/nix-community/nix-index)
