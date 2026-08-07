# bpm extension: optional sccache wrapping in bpm builds
#
# a template opts in by setting bpm_sccache=1 and listing sccache in
# (host_)make_depends. the bpm-sccache hook patches build_env so that, when
# sccache is present in the buildroot, this snippet is sourced and the
# wrapper below exports SCCACHE_DIR and wraps CC/CXX/RUSTC_WRAPPER. every
# compile in the buildroot is then cached in the shared cache
# /var/cache/bpm/build/sccache, which survives bpm's per-package build-dir
# wipes (/var/cache/bpm/build/<pkg>), so e.g. a failed fish crate rebuild
# resumes from cache instead of recompiling LLVM/rustc bindings from scratch.

bpm_sccache_setup() {
    have sccache || return 0
    [ "${bpm_sccache:-0}" = 1 ] || return 0

    export SCCACHE_DIR="${SCCACHE_DIR:-/var/cache/bpm/build/sccache}"
    mkdir -p "$SCCACHE_DIR"

    case "${CC:-}" in sccache\ *) ;; *) CC="sccache ${CC:-cc}"; export CC ;; esac
    case "${CXX:-}" in sccache\ *) ;; *) CXX="sccache ${CXX:-c++}"; export CXX ;; esac

    # a bare RUSTC_WRAPPER="sccache" makes cargo invoke `sccache rustc`
    [ -n "${RUSTC_WRAPPER:-}" ] || { RUSTC_WRAPPER=sccache; export RUSTC_WRAPPER; }
}
