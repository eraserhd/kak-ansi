declare-option -hidden range-specs ansi_color_ranges
declare-option -hidden str ansi_command_file
declare-option -hidden str ansi_filter %sh{
    filterdir="$(dirname $kak_source)/.."
    filter="${filterdir}/kak-ansi-filter"
    if ! [ -x "${filter}" ]; then
        ( cd "$filterdir" && ${CC-c99} -o kak-ansi-filter kak-ansi-filter.c )
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
    try %{
        add-highlighter buffer/ansi ranges ansi_color_ranges
        set-option buffer ansi_color_ranges %val{timestamp}
        set-option buffer ansi_command_file %sh{mktemp}
    }
    execute-keys "|%opt{ansi_filter} -range %val{selection_desc} 2>%opt{ansi_command_file}<ret>"
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
    hook -group ansi buffer BufReadFifo .* %{
        evaluate-commands -draft %{
            select "%val{hook_param}"
            ansi-render-selection
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
