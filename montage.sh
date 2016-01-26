#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
border=2

montage -mode concatenate -tile 2x -geometry 2000x+$border+$border -background white "$@"  montage-tmp.jpg
convert montage-tmp.jpg -bordercolor white -border $borderx$border montage-tmp2.jpg
$DIR/social.sh montage-tmp2.jpg
mv montage-tmp2-social.jpg montage.jpg
rm montage-tmp.jpg
rm montage-tmp2.jpg
