#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
border=20

tile=$1
shift

montage -mode concatenate -tile $tile -geometry 2000x+0+$border -background black "$@"  montage-tmp.jpg
#convert montage-tmp.jpg -bordercolor red -border $borderx$border montage-tmp2.jpg
cp montage-tmp.jpg montage-tmp2.jpg
$DIR/social.sh montage-tmp2.jpg
mv montage-tmp2-social.jpg montage.jpg
rm montage-tmp.jpg
rm montage-tmp2.jpg
