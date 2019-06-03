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
t 'can specify start coord' -flags '-start 8.3' -in '\e[32mxxx' -range '8.3,8.5|*'
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

summarize
