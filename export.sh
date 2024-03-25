#!/bin/bash

# Game version
version=1.2

# Change directory to script directory
cd "$(dirname "$0")"

pico8="$HOME/Videos/pico-8/pico8"

rm -rf build
mkdir build

sed 's/--[^>].*//g' mdpvt.p8 \
    | sed 's/ = /=/g' \
    | sed 's/ += /+=/g' \
    | sed 's/ -= /-=/g' \
    | sed 's/ == /==/g' \
    | sed 's/ != /!=/g' \
    | sed 's/ >= />=/g' \
    | sed 's/ <= /<=/g' \
    | sed 's/ > />/g' \
    | sed 's/ < /</g' \
    | sed 's/ [+] /+/g' \
    | sed 's/ [*] /*/g' \
    | sed 's/ - /-/g' \
    | sed 's/^[/][/]/--/g' \
    | awk '!NF {if (++n <= 1) print; next}; {n=0;print}' \
    > build/mdpvt_stripped.p8


$pico8 build/mdpvt_stripped.p8 -export build/index.html
zip build/index.zip build/index.html build/index.js

$pico8 build/mdpvt_stripped.p8 -export "build/mdvt_$version.p8.png"

$pico8 build/mdpvt_stripped.p8 -export "build/mdvt_$version.bin"
