# BPM Templates Documentation

This document describes the template system used across the FrankenBasix, FrankenUTB, and bpm repositories.

## Overview

The **bpm** package manager uses a template-based system for defining how to build packages. Each package has a `template` file that declares metadata and build instructions. This documentation covers:

- Template structure and syntax
- Available build styles
- Template variables (both required and optional)
- How templates work across repositories
- Examples and best practices

---

## Table of Contents

1. [Template Structure](#template-structure)
2. [Build Styles](#build-styles)
3. [Template Variables](#template-variables)
4. [Repository Organization](#repository-organization)
5. [Template Locations](#template-locations)
6. [Creating New Templates](#creating-new-templates)
7. [Use Flags](#use-flags)
8. [Hooks and Custom Build Phases](#hooks-and-custom-build-phases)
9. [Examples](#examples)
10. [Best Practices](#best-practices)

---

## Template Structure

A template is a shell script (sourced, not executed) that defines package metadata and build configuration. It uses simple `KEY=value` assignments.

### Basic Template Format

```bash
# Comment describing the build style and any special notes
pkg_name=package-name
version=1.2.3
revision=1
build_style=cmake  # or meson, gnu-configure, custom, etc.
short_desc="Brief description of the package"
home_page="https://example.com"
license="MIT"
dist_files="https://example.com/package-1.2.3.tar.gz>package-1.2.3.tar.gz"
checksum="blake3-hash-of-the-distfile"
depends="dep1 dep2 dep3"
```

### Template Types

There are **two types** of templates in the ecosystem:

1. **Skeleton Templates** (in `frankenbasix/templates/`)
   - Minimal templates with only required fields
   - Used as starting points for new packages
   - Contain placeholders for all essential variables

2. **Package Templates** (in individual package directories)
   - Complete templates with all metadata filled in
   - Include build configuration, dependencies, use flags
   - May contain custom hooks (pre_configure, do_build, etc.)

---

## Build Styles

Build styles define how a package is configured, built, checked, and installed. Each build style has a corresponding implementation in `bpm/lib/style/<style>.sh`.

### Available Build Styles

The following build styles are available in your bpm fork:

| Style | Description | Style File | Template File |
|-------|-------------|------------|---------------|
| `custom` | Template defines all build phases itself | `lib/style/custom.sh` | `templates/custom.template` |
| `fetch` | Pre-built binaries, only needs installation | `lib/style/fetch.sh` | `templates/fetch.template` |
| `gnu-configure` | Autoconf-style `./configure` | `lib/style/gnu-configure.sh` | `templates/gnu-configure.template` |
| `gnu-makefile` | Simple Makefile-based builds | `lib/style/gnu-makefile.sh` | `templates/gnu-makefile.template` |
| `cmake` | CMake-based builds | `lib/style/cmake.sh` | `templates/cmake.template` |
| `meson` | Meson-based builds | `lib/style/meson.sh` | `templates/meson.template` |
| `waf` | WAF-based builds | `lib/style/waf.sh` | `templates/waf.template` |
| `waf3` | WAF3-based builds | `lib/style/waf3.sh` | `templates/waf3.template` |
| `cargo` | Rust Cargo-based builds | `lib/style/cargo.sh` | `templates/cargo.template` |
| `go` | Go-based builds | `lib/style/go.sh` | `templates/go.template` |
| `python3-module` | Python module builds | `lib/style/python3-module.sh` | `templates/python3-module.template` |
| `python3-pep517` | PEP 517 wheel builds | `lib/style/python3-pep517.sh` | `templates/python3-pep517.template` |
| `perl-module` | Perl module builds | `lib/style/perl-module.sh` | `templates/perl-module.template` |
| `perl-ModuleBuild` | Perl Module::Build | `lib/style/perl-ModuleBuild.sh` | `templates/perl-ModuleBuild.template` |
| `ruby-module` | Ruby gem builds | `lib/style/ruby-module.sh` | `templates/ruby-module.template` |
| `gemspec` | Ruby gemspec-based | `lib/style/gemspec.sh` | `templates/gemspec.template` |
| `scons` | SCons-based builds | `lib/style/scons.sh` | `templates/scons.template` |
| `qmake` | Qt qmake-based builds | `lib/style/qmake.sh` | `templates/qmake.template` |
| `R-cran` | R CRAN packages | `lib/style/R-cran.sh` | `templates/R-cran.template` |
| `haskell-stack` | Haskell Stack builds | `lib/style/haskell-stack.sh` | `templates/haskell-stack.template` |
| `zig-build` | Zig-based builds | `lib/style/zig-build.sh` | `templates/zig-build.template` |
| `configure` | Generic configure script | `lib/style/configure.sh` | `templates/configure.template` |
| `meta` | Metapackages (no build) | `lib/style/meta.sh` | `templates/meta.template` |

### Build Style Details

Each build style provides default implementations for the build phases:

#### Common Phases

All build styles support these phases (in order):
1. **configure** - Prepare the build (run configure scripts, etc.)
2. **build** - Compile the software
3. **check** - Run tests
4. **install** - Install to DESTDIR

#### Phase Precedence

For each phase, bpm checks in this order:
1. `pre_<phase>` - Pre-hook (always runs first)
2. `do_<phase>` - Template-defined override (highest priority)
3. `style_<phase>` - Build style default implementation
4. `post_<phase>` - Post-hook (always runs last)

This means a template can override any build style behavior by defining its own `do_<phase>` function.

#### Style-Specific Variables

Each build style accepts additional variables:

| Style | Variables |
|-------|-----------|
| `cmake` | `configure_args`, `make_build_args`, `make_check_args`, `make_install_args`, `cmake_build_type` |
| `meson` | `meson_args`, `configure_args`, `make_build_args`, `make_check_args` |
| `gnu-configure` | `configure_args`, `make_build_args`, `make_check_args`, `make_install_args`, `configure_script`, `make_build_target`, `make_check_target`, `make_install_target` |
| `gnu-makefile` | `make_args`, `make_build_args`, `make_check_args`, `make_install_args` |
| `cargo` | `cargo_args`, `make_build_args`, `make_check_args`, `make_install_args` |
| `python3-pep517` | `make_build_args`, `make_check_args`, `make_install_args` |
| `go` | `go_args`, `make_build_args`, `make_check_args` |

---

## Template Variables

### Required Variables

Every template **must** define:

| Variable | Description |
|----------|-------------|
| `pkg_name` | Package name (must match directory name) |
| `version` | Upstream version |
| `revision` | Package revision (bump when updating package without version change) |
| `build_style` | One of the [build styles](#build-styles) |
| `short_desc` | Short description (one line) |
| `home_page` | Upstream homepage URL |
| `license` | License identifier (SPDX format preferred) |
| `dist_files` | Space-separated list of distribution files |
| `checksum` | Blake3 hash of all distfiles (can be generated with `bpm checksum -w`) |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `depends` | Runtime dependencies (space-separated package names) | (none) |
| `make_depends` | Build-time dependencies | Same as `depends` |
| `host_make_depends` | Host tool dependencies (tools needed on build machine) | (none) |
| `wrk_src` | Working source directory name | `${pkg_name}-${version}` |
| `create_wrk_src` | Create a subdirectory for extraction | `no` |
| `skip_extract` | Files to skip during extraction | (none) |

### Use Flag Variables

The bpm template system supports **use flags** for optional features:

| Variable | Description |
|----------|-------------|
| `use_flags` | Space-separated list of all available use flags |
| `use_default` | Default state of use flags (`+` for enabled, `-` for disabled) |

Use flags can be referenced in `configure_args` and other variables using helper functions:

- `$(use_bool flag)` - Returns `--enable-flag` or `--disable-flag` based on flag state
- `$(use_if flag yes-arg no-arg)` - Returns `yes-arg` if flag enabled, `no-arg` if disabled
- `$(use flag)` - Returns `+flag` or `-flag`

Example:
```bash
use_flags="ssl ipv6"
use_default="+ssl -ipv6"
configure_args="$(use_if ssl --with-ssl --without-ssl) $(use_if ipv6 --enable-ipv6 --disable-ipv6)"
```

### Special Variables

| Variable | Description |
|----------|-------------|
| `template` | This file itself (do not set manually) |
| `BPM_JOBS` | Number of parallel build jobs |
| `BPM_VERBOSE` | Verbose output flag |
| `BPM_CACHE` | Cache directory (default: `/var/cache/bpm`) |
| `BPM_REPODIR` | Repository directory |

---

## Repository Organization

### FrankenBasix (`anoraktrend/frankenbasix`)

**Purpose**: Main collection of tested, production-ready package templates.

**Structure**:
```
frankenbasix/
├── templates/           # Skeleton templates for all build styles
│   ├── cmake.template
│   ├── meson.template
│   ├── gnu-configure.template
│   ├── custom.template
│   ├── ... (23 total)
│   └── meta.template
├── packages/            # Actual package directories
│   ├── chimerautils/
│   │   └── template    # Complete package template
│   ├── acl/
│   │   └── template
│   └── ...
├── README.md
└── TEMPLATES.md        # This file
```

**Use Case**: Use this repository for packages you actually use and maintain.

### FrankenUTB (`anoraktrend/frankenutb`)

**Purpose**: Collection of untested, experimental package templates.

**Structure**:
```
frankenutb/
├── sway/
│   └── template
├── libudev-garden/
│   └── template
├── gardenhostd/
│   └── template
├── gardendevd/
│   └── template
└── ...
```

**Use Case**: Use this repository for:
- Packages you don't use yourself but others might want
- Experimental ports (e.g., systemd replacements from Gardenhouse)
- Variants of existing packages (e.g., libudev-garden instead of libudev-zero)

**Note**: All packages in FrankenUTB are **untested** and **unverified** on the maintainer's system.

### bpm (`anoraktrend/bpm`)

**Purpose**: Your fork of the core package manager with template support.

**Structure**:
```
bpm/
├── lib/
│   ├── build.sh        # Main build logic
│   ├── common.sh       # Common functions and template loading
│   └── style/          # Build style implementations
│       ├── cmake.sh
│       ├── meson.sh
│       ├── gnu-configure.sh
│       └── ...
├── etc/
│   ├── bpm.conf        # Default configuration
│   └── repos.conf      # Repository configuration
└── bpm                # Main executable
```

**Use Case**: This is the build system itself. Templates reference build styles defined here.

---

## Template Locations

### Repository Priority

When bpm looks for a package template, it searches repositories in the order defined in `/etc/bpm/repos.conf`. **The first repository providing a template wins.**

Example `repos.conf`:
```
# Highest priority
local /home/me/overlay
frankenbasix https://github.com/anoraktrend/frankenbasix.git main
frankenutb https://github.com/anoraktrend/frankenutb.git main
# Lowest priority
core https://github.com/kkrruumm/basix-packages.git main
```

This means you can **shadow** (override) any package by placing a template in a higher-priority repository.

### Template Resolution

1. bpm checks each repository in order for a directory matching the package name
2. Within that directory, it looks for a file named `template`
3. The first one found is used
4. If `build_style` is set, bpm loads the corresponding style from `bpm/lib/style/`

---

## Creating New Templates

### Starting from a Skeleton

1. Copy the appropriate skeleton from `frankenbasix/templates/`:
   ```bash
   cp frankenbasix/templates/meson.template my-package/template
   ```

2. Edit the template and fill in the required fields:
   ```bash
   pkg_name=my-package
   version=1.0.0
   revision=1
   build_style=meson
   short_desc="My awesome package"
   home_page="https://github.com/me/my-package"
   license="MIT"
   dist_files="https://github.com/me/my-package/archive/v1.0.0.tar.gz>my-package-1.0.0.tar.gz"
   ```

3. Generate the checksum:
   ```bash
   bpm checksum my-package
   # Or to write it directly to the template:
   bpm checksum -w my-package
   ```

4. Add dependencies:
   ```bash
   depends="glibc zlib"
   make_depends="meson pkgconf"
   host_make_depends="meson pkgconf"
   ```

5. Add use flags if needed:
   ```bash
   use_flags="ssl ipv6"
   use_default="+ssl -ipv6"
   configure_args="$(use_if ssl -Dssl=enabled -Dssl=disabled)"
   ```

### Creating a New Build Style

If you need a build style that doesn't exist:

1. Create a new file in `bpm/lib/style/<name>.sh`:
   ```bash
   # build_style=my-style - description
   style_configure() {
       # Configuration commands
   }
   style_build() {
       # Build commands
   }
   style_check() {
       # Test commands
   }
   style_install() {
       # Install commands
   }
   ```

2. Create a skeleton template in `frankenbasix/templates/<name>.template`:
   ```bash
   # build_style=my-style - description
   # variables: my_var1, my_var2
   pkg_name=
   version=
   revision=1
   build_style=my-style
   short_desc=""
   home_page=""
   license=""
   dist_files=""
   checksum=""
   depends=""
   ```

---

## Use Flags

Use flags allow packages to have optional features that can be enabled or disabled at build time.

### Defining Use Flags

```bash
use_flags="feature1 feature2 feature3"
use_default="+feature1 -feature2 +feature3"
```

- `+` prefix means enabled by default
- `-` prefix means disabled by default
- Flags without prefix default to disabled

### Using Use Flags in Templates

#### Helper Functions

| Function | Example | Output (if enabled) | Output (if disabled) |
|----------|---------|---------------------|---------------------|
| `$(use_bool flag)` | `$(use_bool ssl)` | `--enable-ssl` | `--disable-ssl` |
| `$(use_if flag yes no)` | `$(use_if ssl --with-ssl --without-ssl)` | `--with-ssl` | `--without-ssl` |
| `$(use flag)` | `$(use ssl)` | `+ssl` | `-ssl` |

#### Examples

**Meson:**
```bash
configure_args="$(use_if ssl -Dssl=enabled -Dssl=disabled)"
```

**CMake:**
```bash
configure_args="$(use_if ssl -DWITH_SSL=ON -DWITH_SSL=OFF)"
```

**Autoconf:**
```bash
configure_args="$(use_bool ssl) $(use_bool ipv6)"
```

### Global Use Flags

Global use flags can be set in `/etc/bpm/package.use`:
```
# Enable ssl for all packages that support it
* +ssl

# Disable ipv6 for a specific package
my-package -ipv6
```

Precedence (highest to lowest):
1. Package-specific in `package.use`
2. Wildcard in `package.use`
3. Template's `use_default`

---

## Hooks and Custom Build Phases

Templates can define custom behavior at any build phase using hooks.

### Available Hooks

For each phase (configure, build, check, install), you can define:

- `pre_<phase>` - Runs before the phase
- `do_<phase>` - Replaces the style's implementation
- `post_<phase>` - Runs after the phase

### Examples

**Custom configure with environment setup:**
```bash
pre_configure() {
    export CC=clang
    export CXX=clang++
    export CFLAGS="--rtlib=compiler-rt $CFLAGS"
}
```

**Custom build command:**
```bash
do_build() {
    make -j1 V=1  # Override parallel build
}
```

**Post-install cleanup:**
```bash
post_install() {
    # Remove unwanted files
    rm -f "$DESTDIR/usr/share/doc/my-package/README.md"
}
```

**Complete custom build:**
```bash
build_style=custom

do_build() {
    # Custom build logic
    ./custom-build.sh
}

do_install() {
    # Custom install logic
    bmkdir /usr/bin
    bbin "$build_dir/my-program"
}
```

### Helper Functions Available in Templates

The following helper functions are available during build phases:

| Function | Description |
|----------|-------------|
| `bmkdir <dir>` | Create directory in DESTDIR |
| `bbin <file>` | Install binary to DESTDIR/usr/bin |
| `bln <target> <link>` | Create symlink in DESTDIR |
| `bconf <file>` | Install config file to DESTDIR/etc |
| `bsed <args>` | Run sed with proper options |
| `blicense <file>` | Install license file |
| `die <message>` | Exit with error message |

---

## Examples

### Simple CMake Package

```bash
# build_style=cmake - configures into ./build
pkg_name=my-cmake-package
version=1.2.3
revision=1
build_style=cmake
short_desc="A simple CMake package"
home_page="https://github.com/example/my-cmake-package"
license="MIT"
dist_files="https://github.com/example/my-cmake-package/archive/v1.2.3.tar.gz>my-cmake-package-1.2.3.tar.gz"
checksum="abc123..."
depends="glibc"
make_depends="cmake ninja"
host_make_depends="cmake ninja"
```

### Meson Package with Use Flags

```bash
# build_style=meson - configures into ./build, builds with ninja
pkg_name=my-meson-package
version=2.0.0
revision=1
build_style=meson
short_desc="A Meson package with optional features"
home_page="https://example.com"
license="GPL-3.0"
dist_files="https://example.com/my-meson-package-2.0.0.tar.gz"
checksum="def456..."
depends="glibc"
make_depends="meson pkgconf"
host_make_depends="meson pkgconf ninja"

use_flags="ssl ipv6"
use_default="+ssl -ipv6"

configure_args="$(use_if ssl -Dssl=enabled -Dssl=disabled) $(use_if ipv6 -Dipv6=enabled -Dipv6=disabled)"
```

### Custom Build Package

```bash
# build_style=custom - the template defines do_build / do_install itself
pkg_name=custom-package
version=1.0.0
revision=1
build_style=custom
short_desc="Package with custom build process"
home_page="https://example.com"
license="BSD-2-Clause"
dist_files="https://example.com/custom-package-1.0.0.tar.gz"
checksum="ghi789..."
depends=""

do_build() {
    # Custom build steps
    ./configure --prefix=/usr
    make -j$BPM_JOBS
}

do_install() {
    bmkdir /usr/bin
    bmkdir /usr/share/my-package
    bbin "$build_dir/src/my-program"
    cp -r "$build_dir/data/*" "$DESTDIR/usr/share/my-package/"
}
```

### Package with Pre/Post Hooks

```bash
pkg_name=hooked-package
version=1.0.0
revision=1
build_style=cmake
short_desc="Package with build hooks"
home_page="https://example.com"
license="MIT"
dist_files="https://example.com/hooked-package-1.0.0.tar.gz"
checksum="jkl012..."

pre_configure() {
    # Set custom compiler
    export CC=clang
    export CXX=clang++
}

post_install() {
    # Create symlink
    bln /usr/bin/my-program /usr/bin/my-program-alt
    
    # Remove unwanted files
    rm -f "$DESTDIR/usr/share/doc/hooked-package/CHANGELOG"
}
```

---

## Best Practices

### 1. Template Organization

- **Use skeleton templates** from `frankenbasix/templates/` as starting points
- **Keep templates minimal** - only include what's necessary
- **Document special requirements** in comments at the top

### 2. Versioning

- **Bump `revision`** when updating a package without upstream version change
- **Keep `version`** as the upstream version string
- **Use semantic versioning** for packages you maintain

### 3. Dependencies

- **Be explicit** - list all runtime dependencies in `depends`
- **Separate build tools** - use `make_depends` for build-time only deps
- **Host tools** - use `host_make_depends` for tools needed on the build machine
- **Order matters** - dependencies are built in order, list critical deps first

### 4. Use Flags

- **Default to minimal** - disable optional features by default (`-flag`)
- **Enable essential features** - use `+flag` for features most users want
- **Document flags** - add comments explaining what each flag does
- **Test flag combinations** - ensure all flag combinations build correctly

### 5. Checksums

- **Always include checksums** - security and reproducibility
- **Use `bpm checksum -w`** to generate and write checksums automatically
- **Verify upstream hashes** when possible

### 6. Build Styles

- **Use the most specific style** - prefer `meson` over `custom` if Meson is available
- **Don't reinvent the wheel** - use existing styles rather than defining custom do_* for common cases
- **Override when necessary** - use `do_*` functions to override style behavior when needed

### 7. Repository Management

- **FrankenBasix**: Production packages you use and maintain
- **FrankenUTB**: Experimental packages, variants, or packages for others
- **Local overlays**: Use for testing before committing to a shared repo

### 8. Testing

- **Test builds** with `bpm build <package>`
- **Test installs** with `bpm install <package>`
- **Test with different use flags** to ensure all combinations work
- **Verify checksums** after updating distfiles

---

## Quick Reference

### Common Commands

| Command | Description |
|---------|-------------|
| `bpm build <pkg>` | Build a package |
| `bpm install <pkg>` | Install a built package |
| `bpm checksum <pkg>` | Show checksum for package |
| `bpm checksum -w <pkg>` | Update checksum in template |
| `bpm query <pkg>` | Show template metadata and resolved use flags |
| `bpm pull` | Pull all repositories |
| `bpm update` | Update package database |
| `bpm sync` | Sync installed packages with repository |
| `bpm log <pkg>` | Show build log for package |

### Template File Locations

| Repository | Path | Purpose |
|------------|------|---------|
| frankenbasix | `templates/*.template` | Skeleton templates |
| frankenbasix | `<package>/template` | Package templates |
| frankenutb | `<package>/template` | Un tested package templates |
| bpm | `lib/style/*.sh` | Build style implementations |

### Important Files

| File | Purpose |
|------|---------|
| `/etc/bpm/repos.conf` | Repository configuration (priority order) |
| `/etc/bpm/package.use` | Global use flag defaults |
| `/etc/bpm/bpm.conf` | bpm configuration |

---

## Troubleshooting

### Template Not Found

**Error**: `template not found for package X`

**Solution**: 
- Check the package directory exists in one of your repositories
- Verify the repository is listed in `/etc/bpm/repos.conf`
- Check repository priority order

### Build Style Not Found

**Error**: `unknown build_style: X`

**Solution**:
- Check for typos in `build_style`
- Verify the style file exists in `bpm/lib/style/X.sh`
- Ensure you're using your fork of bpm (not the upstream)

### Missing Required Variables

**Error**: `template sets no version` or similar

**Solution**: Ensure all required variables are set:
- `pkg_name`
- `version`
- `revision`
- `build_style`
- `short_desc`
- `home_page`
- `license`
- `dist_files`
- `checksum`

### Checksum Mismatch

**Error**: Checksum verification fails

**Solution**:
- Regenerate checksum with `bpm checksum -w <package>`
- Verify the distfile URL is correct
- Check if upstream has updated the file

### Use Flag Not Recognized

**Error**: Use flag in template but not in `use_flags`

**Solution**: Add the flag to `use_flags` variable

---

## See Also

- [FrankenBasix README](README.md) - Main repository documentation
- [FrankenUTB README](../frankenutb/README.md) - Untested templates repository
- [bpm README](../bpm/README.md) - Core package manager documentation
- [bpm Configuration](bpm/etc/bpm.conf) - Default configuration with comments

---

*This documentation is for the anoraktrend fork of bpm and its associated repositories.*
