# rayngine

> [!tip] Stuck?
> ```
> cmake --build build -- h
> ```
## Getting started

```shell
git clone https://github.com/KotzaBoss/rayngine.git
cd rayngine
cmake -Bbuild
cmake --build build -- rayngine && ./build/bin/rayngine
```

See [[#NixOS]] for details about that particular distribution.
## NixOS

> [!WARNING] **EXPERIMENTAL**

Given it's unique design, you need to setup a shell before working on rayngine. It *should* be as simple as:
```bash
nix develop ./nixos
```
You can then continue hacking normally.

See [[nixos/README|nixos/README]] for more details.
### Sauces
- [Manual](https://nixos.org/manual/nixos/stable/)
- [Packages](https://search.nixos.org/packages?)
- `man configuration.nix`
- [`nix-index`](https://github.com/nix-community/nix-index)
