#!/bin/sh

compile() {
    $CC -g -o kak-ansi-filter kak-ansi-filter.c
    return $?
}

runTest() {
    local test="$1"
    printf ' %s ... ' "$1"
    ./kak-ansi-filter 2>"$test/run-eval" <"$test/in" |od -c >"$test/run-out"
    local ok=true
    if [ -f "$test/out" ] && ! diff -q "$test/run-out" "$test/out" >/dev/null 2>&1; then
        printf '\e[31mfailed (out)\e[0m\n'
        diff -u "$test/out" "$test/run-out"
        ok=false
    fi
    if [ -f "$test/eval" ] && ! diff -q "$test/run-eval" "$test/eval" >/dev/null 2>&1; then
        printf '\e[31mfailed (eval)\e[0m\n'
        diff -u "$test/eval" "$test/run-eval"
        ok=false
    fi
    if $ok; then
        printf 'ok\n'
    fi
}

main() {
    compile || return $?
    local test
    for test in tests/*; do
        if ! [ -d "$test" ]; then
            continue
        fi
        runTest "$test"
    done
}

main "$@" || return $?
