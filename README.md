# FrankenBasix

a bunch of templates to make using basix nicer for me and other users.

FrankenBasix is a spin of [basix-packages](https://github.com/kkrruumm/basix-packages),
which uses the [bpm](https://github.com/kkrruumm/bpm) package manager (specifically, the [anoraktrend fork](https://github.com/anoraktrend/bpm)).

## Documentation

- **[TEMPLATES.md](TEMPLATES.md)** - Complete template system documentation
- **[TEMPLATE-REFERENCE.md](TEMPLATE-REFERENCE.md)** - Quick reference cheat sheet

## FrankenBasix template guidelines

basix-packages only uses a handful of bpm's build styles (gnu-configure, custom, meson,
cmake, python3-pep517, gnu-makefile, configure). FrankenBasix ships a skeleton template for
every build style bpm implements, so any package can be started without having to remember
what the style expects.

## Building Packages

setup your repos.conf

```diff
  # /etc/bpm/repos.conf - package repositories, highest priority first
  #
  #    <name> <git url or absolute path> [branch]
  #
  # git entries are cloned into $BPM_REPODIR/<name> by `bpm pull`, absolute
  # paths are used where they are, which is useful for local "overlays"
  #
  # the first repository providing a template wins, so a local overlay listed
  # above core lets you shadow any package

  #local /home/me/overlay
  core https://github.com/kkrruumm/basix-packages.git main
+ frankenbasix https://github.com/anoraktrend/frankenbasix.git main
```
then, bpm pull && bpm update

To add a new package:

1. copy the matching skeleton out of `templates/` into a new package dir
2. fill in pkg_name, version, revision, dist_files and checksum
3. run `bpm build <pkgdir>` to build and `bpm install <pkgdir>` to install

To maintain a local repository:

1. run `bpm build` for each package
2. copy the archives from `out/` into your repo dir
3. point `/etc/bpm/repos.conf` at your repo dir and run `bpm sync`

## Packages

- `meta-frankenbasix` - a metapackage tying this spin together
- `chimerautils` - Chimera Linux core userland (needs acl, attr, libedit, libxo)
- `acl` - POSIX access control list tools (needs attr)
- `attr` - extended attribute tools
- `libxo` - text/XML/JSON/HTML output library
- `libedit` - BSD line editing library
