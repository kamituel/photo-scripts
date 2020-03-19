#!/bin/sh

# Creates a classic polaroid border around photo,
# 8.8 x 10.7 cm, with photo size 7.9 x 7.9 cm.
# Photo, if not square already, will be cropped.

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Adds extra grey border (2 px wide) around image to make it easier
# to cut if out of larger sheet of paper.
# Output image is written to the *-polaroid.jpg, i.e. for input
# vacation.jpg, output will be vacation-polaroid.jpg.
# Usage:
#   ./polaroid.sh image.jpg
#   ./polaroid.sh image.jpg 300 0  <-- moves image 300px horizontally
#                                      and 0 px vertically when cropping to square.

offset_x=0
offset_y=0

if [ ! -z $2 ]; then
	offset_x=$2
fi

if [ ! -z $3 ]; then
	offset_y=$3
fi


# Original image width / height
width=$(identify "$1" | perl -ne 'print $1 if /.*\s(\d+)x(\d+)\s/')
height=$(identify "$1" | perl -ne 'print $2 if /.*\s(\d+)x(\d+)\s/')
landscape=$(expr $width / $height)

# For landscape pictures, use height to crop square.
# For portait ones, use width.
# So - always use the smaller dimension
if [ $landscape = 1 ]; then
	dimension=$height
else
	dimension=$width
fi

# 7.9 cm at 300 dpi is 933 px
photo_width_px=933
photo_height_px=$photo_width_px

# 8.8 cm at 300 dpi is 1039 px
# 10.7 cm at 300 dpi is 1264 px
paper_width_px=1039
paper_height_px=1264

# Top, left and right border (bottom border is wider)
border_width_px=$( expr \( $paper_width_px - $photo_width_px \) / 2 )
# Bottom border consists of regular border, plus extra space to make it wider
bottom_border_px=$( expr $paper_height_px - $photo_height_px -  2 \* $border_width_px )

out=${1/.jpg/-polaroid.jpg}
out=${out/.JPG/-polaroid.JPG}

convert "$1" \
        -thumbnail ${photo_width_px}x${photo_width_px}^ \
        -extent ${photo_width_px}x${photo_height_px}+${offset_x}+${offset_y} \
        -background white \
        -bordercolor white \
        -gravity south \
	-splice 0x${bottom_border_px} \
        -border  ${border_width_px}x${border_width_px} \
        -density 300 \
        -bordercolor grey \
        -border 2x2 \
        "$out"

