# bpm extension: use_depends
#
# templates may declare, in addition to depends/make_depends:
#
#     use_depends="systemd:systemd, pam:linux-pam; dbus"
#
# entries are separated by ',' or ';', each entry is "flag:pkg" or a bare
# "pkg" (flag = pkg). every enabled flag contributes its package to both
# depends and make_depends. resolved by the bpm-use-depends hook, which
# patches tmpl_load to call use_depends_resolve after the template is
# sourced.

use_depends_resolve() {
    [ -n "${use_depends:-}" ] || return 0
    _ud_ifs=$IFS
    IFS=';,'
    for _ud_e in ${use_depends}; do
        IFS=$_ud_ifs
        _ud_e=${_ud_e#"${_ud_e%%[! ]*}"}
        _ud_e=${_ud_e%"${_ud_e##*[! ]}"}
        [ -n "$_ud_e" ] || continue
        case $_ud_e in
            *:*) _ud_f=${_ud_e%%:*} _ud_p=${_ud_e#*:} ;;
            *) _ud_f=$_ud_e _ud_p=$_ud_e ;;
        esac
        if use "$_ud_f"; then
            for _ud_v in depends make_depends; do
                eval "_ud_c=\${$_ud_v:-}"
                case " $_ud_c " in
                    *" $_ud_p "*) : ;;
                    *) eval "$_ud_v=\"\${$_ud_v:-} $_ud_p\"" ;;
                esac
            done
        fi
    done
    IFS=$_ud_ifs
}
