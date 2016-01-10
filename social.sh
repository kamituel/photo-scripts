#!/bin/sh

# Resizes an image so it longer dimension has 2600px
# and add a caption.

# Usage:
# ./social.sh file.jpg [font-size]
# font-size is optional, use if script makes a bad guess
# about it.

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# -font $DIR/Cabin-Regular-TTF.ttf \
font_color="#bbbbbb"
bg_color=black

width=$(identify "$1" | perl -ne "s/.* (\d+)x(\d+) .*/\$1/; print;")
height=$(identify "$1" | perl -ne "s/.* (\d+)x(\d+) .*/\$2/; print;")
landscape=$(expr $width / $height)

out_longer_dimension=2600
if [ $width = $height ]; then
	width=$out_longer_dimension
	border=$(bc <<< "$width / 36")
	fontsize=$(bc <<< "$width / 45")
	text_offset_y=5
elif [ $landscape = 1 ]; then
        width=$out_longer_dimension
	border=$(bc <<< "$width / 45")
	fontsize=$(bc <<< "$width / 60")
	text_offset_y=6
else
        height=$out_longer_dimension
	border=$(bc <<< "$height / 36")
	fontsize=$(bc <<< "$height / 45")
	text_offset_y=5
fi

if [ ! -z $2 ]; then
	fontsize=$2
fi

convert "$1" \
        -colorspace sRGB \
        -resize ${out_longer_dimension}x${out_longer_dimension}\> \
        -bordercolor $font_color \
        -background $bg_color \
        -bordercolor $bg_color \
        -border ${border}x${border} \
        -font $DIR/Inconsolata-Bold.ttf \
        -fill $font_color \
        -pointsize ${fontsize} \
        -kerning 14 \
        -gravity northwest \
        -annotate +${border}+${text_offset_y} 'KAMIL LESZCZUK' \
        -gravity northeast \
        -annotate +${border}+${text_offset_y} 'KAMITUEL.PL' \
        -append \
        -type truecolor \
        -colorspace sRGB \
        "${1/.jpg/-social.jpg}"

