declare-option -hidden range-specs ansi_color_ranges
declare-option -hidden str ansi_command_file
declare-option -hidden str ansi_filter %sh{
    filterdir="$(dirname $kak_source)/.."
    filter="${filterdir}/kak-ansi-filter"
    if ! [ -x "${filter}" ]; then
        echo "kak-ansi: Compiling kak-ansi-filter.c" >&2
        ( set -x; cd "$filterdir" && ${CC-cc} -o kak-ansi-filter kak-ansi-filter.c )
        if ! [ -x "${filter}" ]; then
            filter=$(command -v cat)
        fi
    fi
    printf '%s' "$filter"
}

define-command \
    -docstring %{ansi-render-selection: colorize ANSI codes contained inside selection

After highlighters are added to colorize the buffer, the ANSI codes
are removed.} \
    -params 0 \
    ansi-render-selection %{
    try ansi-setup-buffer
    ansi-render-selection-impl
}
define-command -hidden ansi-setup-buffer %{
    add-highlighter buffer/ansi ranges ansi_color_ranges
    set-option buffer ansi_color_ranges %val{timestamp}
    set-option buffer ansi_command_file %sh{mktemp}
    hook -always -once buffer BufClose .* %{
	    nop %sh{rm ${kak_opt_ansi_command_file}}
	    set-option buffer ansi_command_file /dev/null
    }
}

define-command -hidden ansi-render-selection-impl %{
    set-register '|' "%opt{ansi_filter} -range %val{selection_desc} 2>%opt{ansi_command_file}"
    execute-keys "|<ret>"
    update-option buffer ansi_color_ranges
    source "%opt{ansi_command_file}"
}

define-command \
    -docstring %{ansi-render: colorize buffer by using ANSI codes  After highlighters are added to colorize the buffer, the ANSI codes are removed.} \
    -params 0 \
    ansi-render %{
    evaluate-commands -draft %{
        execute-keys '%'
        ansi-render-selection
    }
}

define-command \
    -docstring %{ansi-clear: clear highlighting for current buffer.} \
    -params 0 \
    ansi-clear %{
    set-option buffer ansi_color_ranges %val{timestamp}
}

define-command \
    -docstring %{ansi-enable: start rendering new fifo data in current buffer.} \
    -params 0 \
    ansi-enable %{
    try ansi-setup-buffer
    ansi-render
    remove-hooks buffer ansi
    hook -group ansi buffer BufReadFifo .* %{
        evaluate-commands -draft %{
            select "%val{hook_param}"
            ansi-render-selection-impl
        }
    }
}

define-command \
    -docstring %{ansi-disable: stop rendering new fifo content in current buffer.} \
    -params 0 \
    ansi-disable %{
        remove-hooks buffer ansi
    }

hook -group ansi global BufCreate '\*stdin(?:-\d+)?\*' ansi-enable

hook -once -group ansi global KakBegin '.*' %{
    define-command -override -hidden -params ..3 man-impl %{ evaluate-commands %sh{
        buffer_name="$1"
        if [ -z "${buffer_name}" ]; then
            exit
        fi
        shift
        manout=$(mktemp "${TMPDIR:-/tmp}"/kak-man.XXXXXX)
        manerr=$(mktemp "${TMPDIR:-/tmp}"/kak-man.XXXXXX)
        env MANWIDTH=${kak_window_range##* } man "$@" > "$manout" 2> "$manerr"
        retval=$?

        if [ "${retval}" -eq 0 ]; then
            printf %s\\n "
                    edit -scratch %{*$buffer_name ${*}*}
                    execute-keys '%|cat<space>${manout}<ret>gk'
                    ansi-enable
                    nop %sh{ rm ${manout} ${manerr} }
                    set-option buffer filetype man
                    set-option window manpage $buffer_name $*
            "
        else
            printf '
                fail %%{%s}
                nop %%sh{ rm "%s" "%s" }
            ' "$(cat "$manerr")" "${manout}" "${manerr}"
        fi
    } }
}
