declare-option -hidden range-specs ansi_color_ranges
declare-option -hidden str ansi_command_file
declare-option -hidden str ansi_start
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
    evaluate-commands -draft %{
        try %{
            add-highlighter buffer/ansi ranges ansi_color_ranges
            set-option buffer ansi_color_ranges %val{timestamp}
        }
        set-option buffer ansi_command_file %sh{mktemp}
        set-option buffer ansi_start %sh{
            tmp="$kak_selection_desc"
            anchor_line="${tmp%%[.,]*}"
            tmp="${tmp#*[.,]}"
            anchor_column="${tmp%%[.,]*}"
            tmp="${tmp#*[.,]}"
            cursor_line="${tmp%%[.,]*}"
            tmp="${tmp#*[.,]}"
            cursor_column="$tmp"
            if [ $anchor_line -lt $cursor_line ]; then
                printf '%d.%d' "$anchor_line" "$anchor_column"
            elif [ $anchor_line -eq $cursor_line ] && [ $anchor_column -lt $cursor_column ]; then
                printf '%d.%d' "$anchor_line" "$anchor_column"
            else
                printf '%d.%d' "$cursor_line" "$cursor_column"
            fi
        }
        execute-keys "|%opt{ansi_filter} -start %opt{ansi_start} 2>%opt{ansi_command_file}<ret>"
        update-option buffer ansi_color_ranges
        source "%opt{ansi_command_file}"
        nop %sh{ rm -f "$kak_opt_ansi_command_file" }
    }
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
        evaluate-commands -draft %sh{
            printf "select %s\n" "$kak_hook_param"
            printf "execute-keys 'Z<a-:><a-;>gH<a-z>u'\n"
            printf "ansi-render-selection\n"
        }
    }
}

hook -group ansi global BufCreate '\*stdin(?:-\d+)?\*' ansi-enable
