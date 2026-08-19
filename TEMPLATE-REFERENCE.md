# BPM Template Quick Reference

This is a concise cheat sheet for bpm template development. For detailed documentation, see [TEMPLATES.md](TEMPLATES.md).

---

## Template Anatomy

```bash
# Comment: build_style=STYLE - description
pkg_name=name          # REQUIRED: package name (matches dir)
version=1.2.3         # REQUIRED: upstream version
revision=1            # REQUIRED: package revision (bump on updates)
build_style=cmake     # REQUIRED: build system type
short_desc="desc"     # REQUIRED: one-line description
home_page="url"      # REQUIRED: upstream URL
license="MIT"         # REQUIRED: SPDX license identifier
dist_files="url>name" # REQUIRED: source tarball(s)
checksum="hash"       # REQUIRED: blake3 hash of distfiles

depends="dep1 dep2"          # Runtime dependencies
make_depends="dep1 dep2"      # Build-time dependencies (default: same as depends)
host_make_depends="tool1"     # Host tools (meson, cmake, etc.)
wrk_src="name-ver"            # Extract directory name (default: ${pkg_name}-${version})

use_flags="flag1 flag2"       # Available use flags
use_default="+flag1 -flag2"   # Default flag states
configure_args="$(use_if flag1 --with-flag1 --without-flag1)"

# Custom hooks (optional)
pre_configure() { export CC=clang; }
do_build() { make -j1; }
post_install() { rm unwanted files; }
```

---

## Build Styles (23 total)

| Style | Use For | Key Variables |
|-------|---------|---------------|
| `custom` | Custom build process | Define `do_build()`, `do_install()` |
| `fetch` | Pre-built binaries | Define `do_install()` |
| `cmake` | CMake projects | `configure_args`, `cmake_build_type` |
| `meson` | Meson projects | `meson_args`, `configure_args` |
| `gnu-configure` | Autoconf | `configure_args`, `configure_script` |
| `gnu-makefile` | Simple Makefile | `make_args` |
| `cargo` | Rust | `cargo_args` |
| `go` | Go | `go_args` |
| `python3-pep517` | Python wheels | PEP 517 compliant |
| `python3-module` | Python modules | Standard Python |
| `perl-module` | Perl modules | CPAN style |
| `perl-ModuleBuild` | Perl Module::Build | Module::Build |
| `ruby-module` | Ruby gems | Gem style |
| `gemspec` | Ruby gemspec | gemspec based |
| `scons` | SCons | SCons |
| `qmake` | Qt | qmake |
| `waf` | WAF | WAF |
| `waf3` | WAF3 | WAF3 |
| `R-cran` | R packages | CRAN |
| `haskell-stack` | Haskell | Stack |
| `zig-build` | Zig | Zig build |
| `configure` | Generic configure | Generic |
| `meta` | Metapackages | No build |

---

## Use Flag Helpers

```bash
# In template:
use_flags="ssl ipv6 debug"
use_default="+ssl -ipv6 -debug"

# In configure_args or other variables:
$(use_bool ssl)           # --enable-ssl or --disable-ssl
$(use_if ssl --with-ssl --without-ssl)  # --with-ssl or --without-ssl
$(use ssl)                # +ssl or -ssl
```

---

## Hooks

```bash
# Override build phases (pre > do > style > post)
pre_configure()  { setup env; }
do_configure()   { custom configure; }
post_configure() { cleanup; }

pre_build()      { setup; }
do_build()       { custom build; }
post_build()     { cleanup; }

pre_check()      { setup; }
do_check()       { custom tests; }
post_check()     { cleanup; }

pre_install()    { setup; }
do_install()     { custom install; }
post_install()   { cleanup; }
```

---

## Helper Functions

```bash
bmkdir /usr/bin          # Create dir in DESTDIR
bbin "$build_dir/prog"    # Install binary to DESTDIR/usr/bin
bln target link           # Create symlink in DESTDIR
bconf file                # Install config to DESTDIR/etc
bsed args                 # Run sed properly
blicense file             # Install license
die "message"             # Exit with error
```

---

## Common Commands

```bash
# Build and install
bpm build <package>           # Build package
bpm install <package>        # Install built package
bpm build -i <package>       # Build and install

# Template management
bpm checksum <package>       # Show checksum
bpm checksum -w <package>    # Update checksum in template
bpm query <package>          # Show metadata and use flags

# Repository management
bpm pull                    # Pull all repos
bpm update                  # Update package database
bpm sync                    # Sync installed packages

# Debugging
bpm log <package>           # Show build log
bpm -v build <package>      # Verbose build
```

---

## Repository Priority

Templates are found in order from `/etc/bpm/repos.conf`:

```
# Highest priority first
local /home/me/overlay
frankenbasix https://github.com/anoraktrend/frankenbasix.git main
frankenutb https://github.com/anoraktrend/frankenutb.git main
core https://github.com/kkrruumm/basix-packages.git main
```

**First match wins** - you can shadow any package with a local template.

---

## Creating a New Package

```bash
# 1. Copy skeleton
cp frankenbasix/templates/meson.template my-package/template

# 2. Edit template (fill in required fields)
vim my-package/template

# 3. Generate checksum
bpm checksum -w my-package

# 4. Build and test
bpm build my-package
bpm install my-package
```

---

## Template Locations

| Purpose | Location |
|---------|----------|
| Skeleton templates | `frankenbasix/templates/*.template` |
| Production packages | `frankenbasix/<name>/template` |
| Untested packages | `frankenutb/<name>/template` |
| Build style impls | `bpm/lib/style/*.sh` |

---

## Required Variables Checklist

- [ ] `pkg_name` - matches directory name
- [ ] `version` - upstream version
- [ ] `revision` - start at 1, bump on updates
- [ ] `build_style` - one of 23 styles
- [ ] `short_desc` - one line
- [ ] `home_page` - URL
- [ ] `license` - SPDX identifier
- [ ] `dist_files` - source URL(s)
- [ ] `checksum` - blake3 hash

---

## Common Patterns

### Meson with Options

```bash
build_style=meson
use_flags="gtk gnome"
use_default="+gtk -gnome"
configure_args="$(use_if gtk -Dgtk=enabled -Dgtk=disabled) $(use_if gnome -Dgnome=enabled -Dgnome=disabled)"
```

### CMake with Type

```bash
build_style=cmake
cmake_build_type=Release
configure_args="-DCMAKE_BUILD_TYPE=${cmake_build_type:-Release}"
```

### Autoconf Standard

```bash
build_style=gnu-configure
configure_args="--disable-static --enable-shared"
```

### Custom with Environment

```bash
build_style=custom
pre_configure() {
    export CC=clang
    export CFLAGS="-O2 $CFLAGS"
}
do_build() { make -j$BPM_JOBS; }
do_install() { make DESTDIR="$DESTDIR" install; }
```

---

## Use Flag Precedence

1. `/etc/bpm/package.use` - package-specific
2. `/etc/bpm/package.use` - wildcard (`*`)
3. Template's `use_default`

Example `package.use`:
```
# Enable ssl globally
* +ssl

# Disable for specific package
my-package -ssl
```

---

## Debugging Tips

1. **Check template is loaded**: `bpm query <package>`
2. **Verbose build**: `bpm -v build <package>`
3. **View log**: `bpm log <package>`
4. **Check checksum**: `bpm checksum <package>`
5. **Verify distfile**: `ls $BPM_CACHE/sources/<package>/`

---

## File Structure Example

```
frankenbasix/
├── templates/
│   └── meson.template      # Skeleton
└── my-package/
    ├── template             # Package template
    ├── files/               # Additional files (patches, configs)
    │   └── my-package.conf
    └── patches/             # Patches
        └── fix-build.patch
```

---

*For complete documentation, see [TEMPLATES.md](TEMPLATES.md)*
