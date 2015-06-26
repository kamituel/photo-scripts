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
	border=$(bc <<< "$width / 75")
        top_border=$(bc <<< "$border * 1.5")
	fontsize=$(bc <<< "$width / 60")
	text_offset_y=$(bc <<< "$width / 120")
else
        height=$out_longer_dimension
	border=$(bc <<< "$height / 55")
        top_border=$(bc <<< "$border * 1.5")
	fontsize=$(bc <<< "$height / 50")
	text_offset_y=$(bc <<< "$height / 80")
fi

if [ ! -z $2 ]; then
	fontsize=$2
fi

convert $1 \
        -resize ${out_longer_dimension}x${out_longer_dimension}\> \
        -bordercolor $font_color \
        -border 3x3 \
        -background $bg_color \
        -splice 0x${top_border} \
        -bordercolor $bg_color \
        -border ${border}x${border} \
        -font $DIR/Inconsolata-Bold.ttf \
        -fill $font_color \
        -pointsize ${fontsize} \
        -gravity north \
        -kerning 14 \
        -annotate +0+${text_offset_y} 'KAMIL  LESZCZUK  -  KAMITUEL.PL' \
        -append \
        ${1/.jpg/-social.jpg}

