#!/bin/sh

# Resizes an image so it longer dimension has 2000px
# and add a caption.

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

convert $1 \
        -resize 2000x2000\> \
        -bordercolor black \
        -border 2%x \
        -font $DIR/UnicaOne-Regular.ttf \
        -fill '#DDDDDD' \
        -pointsize 30 \
        -gravity north \
        -annotate +0+2 'KAMIL LESZCZUK : KAMITUEL.PL' \
        -append \
        ${1/.jpg/-social.jpg}

