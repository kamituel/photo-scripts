#!/bin/sh

# Resizes an image so it longer dimension has 2000px
# and add a caption.

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

font_color=white
bg_color=black

convert $1 \
        -resize 2600x2600\> \
        -background $bg_color \
        -splice 0x25 \
        -bordercolor $bg_color \
        -border 25x25 \
        -font $DIR/Cabin-Regular-TTF.ttf \
        -fill $font_color \
        -pointsize 36 \
        -gravity north \
        -annotate +0+3 'K A M I L   L E S Z C Z U K   -   K A M I T U E L . P L' \
        -append \
        ${1/.jpg/-social.jpg}

