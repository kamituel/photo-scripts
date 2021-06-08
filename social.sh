#!/bin/sh

# Resizes an image so it longer dimension has 2600px
# and add a caption.

# Usage:
# ./social.sh file.jpg [font-size]
# font-size is optional, use if script makes a bad guess
# about it.

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# -font $DIR/Cabin-Regular-TTF.ttf \
font_color="#ffffff"
bg_color="#000000"
# font_color="#000000"
# bg_color="#ffffff"

width=$(identify "$1" | perl -ne "s/.* (\d+)x(\d+) .*/\$1/; print;")
height=$(identify "$1" | perl -ne "s/.* (\d+)x(\d+) .*/\$2/; print;")
landscape=$(expr $width / $height)

out_longer_dimension=2600
if [ -z "$SMALL_BORDER" ] && [ -z "${NO_BORDER}" ]; then
  if [ $width = $height ]; then
    width=$out_longer_dimension
    border=$(bc <<< "$width / 45")
    fontsize=$(bc <<< "$width / 80")
    text_offset_y=$(bc <<< "${fontsize} - 5")
  elif [ $landscape = 1 ]; then
    width=$out_longer_dimension
    border=$(bc <<< "$width / 60")
    fontsize=$(bc <<< "$width / 105")
    text_offset_y=$(bc <<< "${fontsize} - 5")
  else
    height=$out_longer_dimension
    border=$(bc <<< "$height / 50")
    fontsize=$(bc <<< "$height / 105")
    text_offset_y=$(bc <<< "${fontsize} + 2")
  fi
elif [ -z "${NO_BORDER}" ]; then
  if [ $width = $height ]; then
  	width=$out_longer_dimension
  	border=$(bc <<< "$width / 85")
  	fontsize=$(bc <<< "$width / 90")
  	text_offset_y=2
  elif [ $landscape = 1 ]; then
    width=$out_longer_dimension
  	border=$(bc <<< "$width / 100")
  	fontsize=$(bc <<< "$width / 105")
  	text_offset_y=2
  else
    height=$out_longer_dimension
  	border=$(bc <<< "$height / 100")
  	fontsize=$(bc <<< "$height / 105")
  	text_offset_y=3
  fi
else
  if [ $width = $height ]; then
  	width=$out_longer_dimension
  	border=0
    fontsize=1
  elif [ $landscape = 1 ]; then
    width=$out_longer_dimension
  	border=0
    fontsize=1
  else
    height=$out_longer_dimension
  	border=0
    fontsize=1
  fi
fi

if [ ! -z $2 ]; then
	fontsize=$2
fi

if [ -z "$SMALL_BORDER" ] && [ -z "$NO_BORDER" ]; then
  AUTHOR="KAMIL LESZCZUK"
  WEBSITE="KAMITUEL.PL"
else
  AUTHOR=""
  WEBSITE=""
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
        -kerning 10 \
        -gravity northwest \
        -annotate +${border}+${text_offset_y} "$AUTHOR" \
        -gravity northeast \
        -annotate +${border}+${text_offset_y} "$WEBSITE" \
        -append \
        -type truecolor \
        -colorspace sRGB \
        "${1/.jpg/-social.jpg}"
