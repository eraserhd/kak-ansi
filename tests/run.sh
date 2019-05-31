#!/bin/sh

compile() {
    $CC -o kak-ansi-filter kak-ansi-filter.c
}

runTest() {
    local test="$1"
    printf ' %s ... ' "$1"
    ./kak-ansi-filter <"$test/in" |od -c >"$test/run"
    if ! diff -q "$test/run" "$test/out" >/dev/null; then
        printf '\e[31mfailed\e[0m\n'
        diff -u "$test/run" "$test/out"
    else
        printf 'ok\n'
    fi
}

main() {
    compile
    local test
    for test in tests/*; do
        if ! [ -d "$test" ]; then
            continue
        fi
        runTest "$test"
    done
}

main "$@"
