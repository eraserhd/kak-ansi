h2() {
    printf '\n \e[33;1m%s\e[0m\n' "$1"
}

t() {
    local in
    local has_out=false out
    local ranges=()
    local description="$1"
    shift
    while (( $# > 0 )); do
        case "$1" in
            -in) shift; in="$1";;
            -out) shift; has_out=true; out="$1";;
            -range) shift; ranges+=( "$1" );;
        esac
        shift
    done

    printf '   %s ... ' "$description"

    local ok=true
    local commands=$(mktemp)
    local actual_out=$(printf "$in" | ./kak-ansi-filter 2>"$commands")
    if $has_out && [[ $out != $actual_out ]]; then
        ok=false
        printf '\e[31mfailed\e[0m\n'
        printf '      Expected output: %s\n' "$out"
        printf '        Actual output: %s\n' "$actual_out"
        printf '\n'
    fi
    for range in "${ranges[@]}"; do
        if ! grep -qF " $range" "$commands"; then 
            if $ok; then
                printf '\e[31mfailed\e[0m\n'
            fi
            ok=false
            printf '      Expected range: %s\n' "$range"
            printf '       Commands were: %s\n' "$(cat "$commands")"
            printf '\n'
        fi
    done
    rm -f "$commands"
    if $ok; then
        printf 'ok\n'
    fi
}

$CC -g -o kak-ansi-filter kak-ansi-filter.c || exit $?
