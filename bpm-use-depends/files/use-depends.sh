# bpm extension: use_depends / use_make_depends / use_host_make_depends
#
# templates may declare, in addition to depends/make_depends:
#
#     use_depends="systemd:systemd pam:linux-pam"
#     use_make_depends="systemd"
#     use_host_make_depends="rust"
#
# entries are whitespace-separated, each entry is "flag:pkg" or a bare
# "pkg" (flag = pkg). every enabled flag contributes its package to the
# matching dependency lists: use_depends to both depends and make_depends,
# use_make_depends to make_depends only, use_host_make_depends to
# host_make_depends only. resolved by the bpm-use-depends hook, which
# patches tmpl_load to call use_depends_resolve after the template is
# sourced.

use_depends_resolve() {
    _ud_fold "$use_depends" depends make_depends
    _ud_fold "$use_make_depends" make_depends
    _ud_fold "$use_host_make_depends" host_make_depends
}

_ud_fold() {
    [ -n "${1:-}" ] || return 0
    _ud_list=$1
    shift
    for _ud_e in $_ud_list; do
        case $_ud_e in
            *:*) _ud_f=${_ud_e%%:*} _ud_p=${_ud_e#*:} ;;
            *) _ud_f=$_ud_e _ud_p=$_ud_e ;;
        esac
        use "$_ud_f" || continue
        for _ud_v; do
            eval "_ud_c=\${$_ud_v:-}"
            case " $_ud_c " in
                *" $_ud_p "*) : ;;
                *) eval "$_ud_v=\"\${$_ud_v:-} $_ud_p\"" ;;
            esac
        done
    done
}
