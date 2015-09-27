#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

montage -mode concatenate -tile 2x -geometry 2000x+10+10 -background white "$@"  montage-tmp.jpg
convert montage-tmp.jpg -bordercolor white -border 10x10 montage-tmp2.jpg
$DIR/social.sh montage-tmp2.jpg
mv montage-tmp2-social.jpg montage.jpg
rm montage-tmp.jpg
rm montage-tmp2.jpg
