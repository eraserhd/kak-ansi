#!/usr/bin/env bash
source tests/functions.bash

h2 "Fixing Output"
t 'removes ANSI escapes' -in ' \e[32m 1.\e[39m hello' -out '  1. hello'
t '\e(0 selects line-drawing' -in '\e(0jklmnqtuvwx' -out '┘┐┌└┼─├┤┴┬│'
t '\e(B resets line-drawing' -in '\e(0\e(Bjklmnqtuvwx' -out 'jklmnqtuvwx'
t 'ASCII SO selects line-drawing' -in '\x0Ejklmnqtuvwx' -out '┘┐┌└┼─├┤┴┬│'
t 'ASCII SI resets line-drawing' -in '\x0E\x0Fjklmnqtuvwx' -out 'jklmnqtuvwx'

h2 "Computing Ranges"
t 'emits face at EOF' -in '\e[32mxxx' -range '1.1,1.3|*'
t 'does not emit default face' -in '\e[39mxxx' -no-ranges
t 'new face for fg change' -in '\e[32mxxx\e[31myyy' -range '1.1,1.3|*' -range '1.4,1.6|*'
t 'new face for bg change' -in '\e[45mxxx\e[41myyy' -range '1.1,1.3|*' -range '1.4,1.6|*'
t 'merges ranges at BOF' -in '\e[32m\e[1mxxx' -range '1.1,1.3|green+b'
t 'merges ranges' -in 'y\e[32m\e[1mxxx' -range '1.2,1.4|green+b'
t 'no new face if no change' -in '\e[31mxxx\e[31myyy' -range '1.1,1.6|*'
t 'handles change at 2.1' -in 'xy\n\e[31mxxx' -range '2.1,2.3|*'
t 'handles change at EOL' -in 'xy\e[31m\nxxx' -range '1.3,2.3|*'
t 'can specify range'  -flags '-range 8.3,10.2' -in '\e[32mxxx' -range '8.3,8.5|*'
t 'advances using byte offsets' -in '┘\e[32mx' -range '1.4,1.4|green'
t 'covers ending char bytes' -in '\e[31m┘\e[32mx' -range '1.1,1.3|red' -range '1.4,1.4|green'

h2 "Foreground Color"
t 'adds ranges for fg colors' -in ' \e[32m 1.' -range '1.2,1.4|green'
t '\e[39m resets fg' -in ' \e[32m 1.\e[39mxx' -range '1.2,1.4|green'
t '\e[0m resets fg' -in ' \e[32m 1.\e[0m hello' -range '1.2,1.4|green'
t '\e[m resets fg' -in ' \e[32m 1.\e[m hello' -range '1.2,1.4|green'
t '\e[38;2;r;g;bm sets true fg' -in '\e[38;2;253;17;129mxxx' -range '1.1,1.3|rgb:FD1181'
t '\e[38;5;0-7m sets ANSI color' -in '\e[38;5;2mxxx' -range '1.1,1.3|green'
t '\e[38;5;8-15m sets bright ANSI color' -in '\e[38;5;10mxxx' -range '1.1,1.3|bright-green'
t '\e[38;5;16-231m sets from 666 cube' -in '\e[38;5;121mxxx' -range '1.1,1.3|rgb:87FFAF'
t '\e[38;5;232-255m sets greyscale' -in '\e[38;5;239mxxx' -range '1.1,1.3|rgb:4E4E4E'
#t 'can set palette colors'

h2 "Background Color"
t 'adds ranges for bg colors' -in ' \e[41m 1.' -range '1.2,1.4|default,red'
t '\e[49m resets bg' -in ' \e[41m 1.\e[49mx' -range '1.2,1.4|default,red'
t '\e[0m resets bg' -in ' \e[42m 1.\e[0m hello' -range '1.2,1.4|default,green'
t '\e[m resets bg' -in ' \e[42m 1.\e[m hello' -range '1.2,1.4|default,green'
t '\e[48;2;r;g;bm sets true bg' -in '\e[48;2;17;129;253mxxx' -range '1.1,1.3|default,rgb:1181FD'

h2 "Attributes"
h3 "Bold"
t '\e[1m sets bold' -in 'x\e[1mxx' -range '1.2,1.3|default+b'
t '\e[21m resets bold' -in 'x\e[1mx\e[21mx' -range '1.2,1.2|*'
t '\e[0m resets bold' -in 'x\e[1mx\e[0mx' -range '1.2,1.2|*'
t '\e[22m resets bold' -in 'x\e[1mx\e[22mx' -range '1.2,1.2|*'

h3 "Dim"
t '\e[2m sets dim' -in '\e[2mxxx' -range '1.1,1.3|default+d'
t '\e[0m resets dim' -in '\e[2mx\e[0mx' -range '1.1,1.1|default+d'
t '\e[22m resets dim' -in '\e[2mxx\e[22mx' -range '1.1,1.2|default+d'

h3 "Italic"
t '\e[3m sets italic' -in '\e[3mxxx' -range '1.1,1.3|default+i'
t '\e[0m resets italic' -in '\e[3mx\e[0mxx' -range '1.1,1.1|default+i'
t '\e[23m resets italic' -in '\e[3mx\e[23mxx' -range '1.1,1.1|default+i'

h3 "Underline"
t '\e[4m sets underline' -in '\e[4mxxx' -range '1.1,1.3|default+u'
t '\e[0m resets underline' -in '\e[4mx\e[0mx' -range '1.1,1.1|default+u'
t '\e[24m resets underline' -in '\e[4mx\e[24mx' -range '1.1,1.1|default+u'

h3 "Blink"
t '\e[5m sets blink' -in '\e[5mxxx' -range '1.1,1.3|default+B'
t '\e[0m resets blink' -in '\e[5mx\e[0mx' -range '1.1,1.1|default+B'
t '\e[25m resets blink' -in '\e[5mx\e[25mx' -range '1.1,1.1|default+B'

h3 "Reverse"
t '\e[7m sets reverse' -in '\e[7mxxx' -range '1.1,1.3|default+r'
t '\e[0m resets all attributes' -in '\e[7mx\e[0mx' -range '1.1,1.1|default+r'
t '\e[27m resets inverse' -in '\e[7mx\e[27mx' -range '1.1,1.1|default+r'

h2 "Old Line Printer Escapes"
h3 "Bold Overstrike"
t 'removes backspaces' -in ' H\bHe\bel\bll\blo\bo ' -out ' Hello '
t 'sets and resets boldface' -in ' H\bHe\bello' -range '1.2,1.3|default+b'

h3 "Underline Overstrike"
t 'removes underscore-backspace' -in ' _\bH_\be_\bl_\bl_\bo ' -out ' Hello '
t 'removes backspace-underscore' -in ' H\b_e\b_l\b_l\b_o\b_ ' -out ' Hello '
t 'sets and resets underline' -in ' H\b__\bel\b_lo ' -range '1.2,1.4|default+u'

h3 "Combined Overstrike"
t 'removes combined overstrikes' -in ' H\bH\b__\be\bel\b_\bllo ' -out ' Hello '
t 'sets and resets bold and underline' -in ' H\bH\b__\be\bel\b_\bllo ' -range '1.2,1.4|default+ub'

h3 "Other Overstrikes"
t 'are discarded' -in 'X\bY' -out 'Y'

h2 "Shell Integration"
t 'removes hyperlink escapes' -in 'editor: \e]8;;https://kakoune.org/\e\\kakoune\e]8;;\e\\' -out 'editor: kakoune'
t 'removes hyperlink escapes terminated by BEL' -in 'editor: \e]8;;https://kakoune.org/\akakoune\e]8;;\a' -out 'editor: kakoune'
t 'ignores shell integration esapes' -in 'hello\e]133;A\e\\world' -out 'helloworld'
long_uri="https://kakoune.org/$(printf 'a%.0s' {1..2000})"
huge_uri="https://kakoune.org/$(printf 'a%.0s' {1..10000})"
t 'keeps text after long OSC escapes' -in 'editor: \e]8;;'"$long_uri"'\e\\kakoune\e]8;;\e\\ rocks' -out 'editor: kakoune rocks'
t 'keeps text after OSC escapes too long to process' -in 'editor: \e]8;;'"$huge_uri"'\e\\kakoune\e]8;;\e\\ rocks' -out 'editor: kakoune rocks'

h2 "Hyperlinks"
t 'records hyperlinked text' -in 'editor: \e]8;;https://kakoune.org/\e\\kakoune\e]8;;\e\\' -link "'1.9,1.15|https://kakoune.org/'"
t 'records hyperlinks terminated by BEL' -in 'editor: \e]8;;https://kakoune.org/\akakoune\e]8;;\a' -link "'1.9,1.15|https://kakoune.org/'"
t 'records hyperlinks with parameters' -in '\e]8;id=1:x=y;https://kakoune.org/\e\\kak\e]8;;\e\\' -link "'1.1,1.3|https://kakoune.org/'"
t 'records long hyperlinks' -in '\e]8;;'"$long_uri"'\e\\kak\e]8;;\e\\' -link "'1.1,1.3|$long_uri'"
t 'does not record hyperlinks without text' -in 'x\e]8;;https://kakoune.org/\e\\\e]8;;\e\\y' -no-links
t 'records no hyperlinks for plain text' -in 'kakoune' -no-links
t 'starting a hyperlink ends the previous one' -in '\e]8;;https://a.org/\e\\ab\e]8;;https://b.org/\e\\cd\e]8;;\e\\' -link "'1.1,1.2|https://a.org/'" -link "'1.3,1.4|https://b.org/'"
t 'records hyperlinks left open at end of input' -in 'x\e]8;;https://kakoune.org/\e\\kak' -link "'1.2,1.4|https://kakoune.org/'"
t 'records hyperlinks spanning lines' -in '\e]8;;https://kakoune.org/\e\\ab\ncd\e]8;;\e\\' -link "'1.1,2.2|https://kakoune.org/'"
t 'does not count other escapes as hyperlinked text' -in '\e]8;;https://kakoune.org/\e\\a\e[31mb\e[0mc\e]8;;\e\\' -link "'1.1,1.3|https://kakoune.org/'" -range '1.2,1.2|red'
t 'covers every byte of hyperlinked characters' -in '\e]8;;https://kakoune.org/\e\\é\e]8;;\e\\' -link "'1.1,1.2|https://kakoune.org/'"
t 'offsets hyperlinks by the rendered range' -flags '-range 8.3,10.2' -in '\e]8;;https://kakoune.org/\e\\kak\e]8;;\e\\' -link "'8.3,8.5|https://kakoune.org/'"
t 'quotes hyperlinks for Kakoune' -in "\e]8;;https://e.org/it's\\\\a|b\e\\\\x\e]8;;\e\\\\" -link "'1.1,1.1|https://e.org/it''s\\\\a\\|b'"

h2 "Common Private Modes"
t 'ignores common private modes escapes' -in 'hello\e[?47hworld' -out 'helloworld'

summarize
