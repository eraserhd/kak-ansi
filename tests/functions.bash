TEST_COUNT=0
TESTS_FAILED=0
TEST_OK=true
TEST_OUTPUT=''
TEST_RANGES=()
TEST_LINKS=()

h2() {
    printf '\n \e[33;1m%s\e[0m\n' "$1"
}

h3() {
    printf '   \e[33m%s\e[0m\n' "$1"
}

hasGlob() {
    local pattern="$1"
    shift
    pattern="${pattern//\\/\\\\}"
    pattern="${pattern//\./\\.}"
    pattern="${pattern//\*/.*}"
    pattern="${pattern//\|/\\|}"
    pattern="${pattern//\?/.}"
    pattern="${pattern//\+/\\+}"
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
    local escaped_out="$TEST_OUT"
    escaped_out="${escaped_out///\\x0E}"
    escaped_out="${escaped_out///\\x0F}"
    printf '      Assertion: \e[31m%s\e[0m\n' "$*"
    printf "         Output: '%s'\n" "$escaped_out"
    printf "         Ranges: %s\n" "${TEST_RANGES[*]}"
    printf "          Links: %s\n" "${TEST_LINKS[*]}"
    printf '\n'
}

expectWords() {
    local flag="$1" name="$2"
    local -n expected_words="$3" actual_words="$4"
    local pattern
    for pattern in "${expected_words[@]}"; do
        if ! hasGlob "$pattern" "${actual_words[@]}"; then
            fail "$flag" "$pattern"
        fi
    done
    if (( ${#actual_words[@]} != ${#expected_words[@]} )); then
        fail "count of $name"
    fi
}

t() {
    local description="$1"
    shift
    local in='' flags=''
    while [[ -z "$in" ]]; do
        case "$1" in
            -in)
                in="$2"
                shift 2
                ;;
            -flags)
                flags="$2"
                shift 2
                ;;
        esac
    done

    printf '     %s ... ' "$description"
    local commands_file=$(mktemp)
    TEST_OUT=$(printf "$in" | ./kak-ansi-filter $flags 2>"$commands_file")
    local command_words link_words
    {
        read -ra command_words
        read -ra link_words
    } <"$commands_file"
    TEST_RANGES=( "${command_words[@]:4}" )
    TEST_LINKS=( "${link_words[@]:4}" )
    local ranges_specified=false expected_ranges=()
    local links_specified=false expected_links=()
    TEST_OK=true

    while (( $# > 0 )); do
        case "$1" in
        -out)
            if [[ $2 != $TEST_OUT ]]; then
                fail "$1" "$2"
            fi
            shift 2
            ;;
        -range)
            ranges_specified=true
            expected_ranges+=( "$2" )
            shift 2
            ;;
        -no-ranges)
            ranges_specified=true
            shift
            ;;
        -link)
            links_specified=true
            expected_links+=( "$2" )
            shift 2
            ;;
        -no-links)
            links_specified=true
            shift
            ;;
        *)
            fail "$1"
            shift
            ;;
        esac
    done

    if $ranges_specified; then
        expectWords -range ranges expected_ranges TEST_RANGES
    fi
    if $links_specified; then
        expectWords -link links expected_links TEST_LINKS
    fi

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
    if (( TESTS_FAILED > 0 )); then
        exit 1
    fi
}

make CFLAGS='-g' || exit $?
