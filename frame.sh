#!/bin/sh

# Usage:
#   ./frame.sh image.jpg frame-color frame-width-percent

if [ -z $2 ]; then
	echo "Usage: ./frame.sh image.jpg white 10"
	exit 1
fi

if [ -z $3 ]; then
	echo "Usage: ./frame.sh image.jpg white 10"
	exit 1
fi

frame_color=$2
frame_width=$3

# Original image width / height
width=$(identify $1 | cut -d \  -f 3 | cut -d x -f 1)
height=$(identify $1 | cut -d \  -f 3 | cut -d x -f 2)

border_width_px=$( expr $width \* $frame_width / 100 )

convert $1 \
        -bordercolor $frame_color \
        -border  ${border_width_px}x${border_width_px} \
        ${1/.jpg/-framed.jpg}

