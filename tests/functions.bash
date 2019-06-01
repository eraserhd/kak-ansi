TEST_COUNT=0
TESTS_FAILED=0
TEST_OK=true

h2() {
    printf '\n \e[33;1m%s\e[0m\n' "$1"
}

hasGlob() {
    local pattern="$1"
    shift
    pattern="${pattern//\./\\.}"
    pattern="${pattern//\*/.*}"
    pattern="${pattern//\|/\\|}"
    pattern="${pattern//\?/.}"
    pattern="^${pattern}$"
    local word
    for word in "$@"; do
        if [[ $word =~ $pattern ]]; then
            return 0
        fi
    done
    return 1
}

fail() {
    if $TEST_OK; then
        printf '\e[31;1mfailed\e[0m\n'
    fi
    TEST_OK=false
}

t() {
    local description="$1"
    local in="$3"
    shift 3
    printf '   %s ... ' "$description"
    local commands_file=$(mktemp)
    local actual_out=$(printf "$in" | ./kak-ansi-filter 2>"$commands_file")
    local actual_commands=()
    read -ra actual_commands <"$commands_file"
    rm -f "$commands_file"

    TEST_OK=true

    while (( $# > 0 )); do
        case "$1" in
        -out)
            shift
            local out="$1"
            if [[ $out != $actual_out ]]; then
                fail
                printf '      Expected output: %s\n' "$out"
                printf '        Actual output: %s\n' "$actual_out"
                printf '\n'
            fi
            ;;
        -range)
            shift
            if ! hasGlob "$1" "${actual_commands[@]}"; then
                fail
                printf '      Expected range: %s\n' "$1"
                printf '       Commands were: %s\n' "${actual_commands[*]}"
                printf '\n'
            fi
            ;;
        -no-range)
            shift
            if hasGlob "$1" "${actual_commands[@]}"; then
                fail
                printf '    Unexpected range: %s\n' "$1"
                printf '       Commands were: %s\n' "${actual_commands[*]}"
                printf '\n'
            fi
            ;;
        -no-ranges)
            if hasGlob "*|*" "${actual_commands[@]}"; then
                fail
                printf '      Expected no ranges.\n'
                printf '      Commands were: %s\n' "${actual_commands[*]}"
                printf '\n'
            fi
            ;;
        *)
            fail
            printf '     Invalid option %s.\n' "$1"
            printf '\n'
            ;;
        esac
        shift
    done

    TEST_COUNT=$(( TEST_COUNT + 1 ))
    if $TEST_OK; then
        printf 'ok\n'
    else
        TESTS_FAILED=$(( TESTS_FAILED + 1 ))
    fi
}

summarize() {
    local color=''
    if (( TESTS_FAILED > 0 )); then
        color="$(printf '\e[31;1m')"
    fi
    printf '\n%s%d tests, %d failed.\e[0m\n' "$color" $TEST_COUNT $TESTS_FAILED
}

$CC -g -o kak-ansi-filter kak-ansi-filter.c || exit $?
