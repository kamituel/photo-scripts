#!/bin/sh

# Resizes an image so it longer dimension has 2600px
# and add a caption.

# Usage:
# ./social.sh file.jpg [font-size]
# font-size is optional, use if script makes a bad guess
# about it.

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# -font $DIR/Cabin-Regular-TTF.ttf \
font_color=white
bg_color=black

width=$(identify $1 | cut -d \  -f 3 | cut -d x -f 1)
height=$(identify $1 | cut -d \  -f 3 | cut -d x -f 2)
landscape=$(expr $width / $height)

out_longer_dimension=2600

if [ $landscape = 1 ]; then
        width=$out_longer_dimension
	border=$(bc <<< "$width / 100")
	fontsize=$(bc <<< "$width / 80")
	text_offset_y=$(bc <<< "$width / 270")
else
        height=$out_longer_dimension
	border=$(bc <<< "$height / 60")
	fontsize=$(bc <<< "$height / 60")
	text_offset_y=$(bc <<< "$height / 120")
fi

if [ ! -z $2 ]; then
	fontsize=$2
fi

convert $1 \
        -resize ${out_longer_dimension}x${out_longer_dimension}\> \
        -background $bg_color \
        -splice 0x${border} \
        -bordercolor $bg_color \
        -border ${border}x${border} \
        -font $DIR/Inconsolata-Bold.ttf \
        -fill $font_color \
        -pointsize ${fontsize} \
        -gravity north \
        -annotate +0+${text_offset_y} 'K A M I L   L E S Z C Z U K   -   K A M I T U E L . P L' \
        -append \
        ${1/.jpg/-social.jpg}

