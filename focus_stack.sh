#!/bin/sh

export PATH=$PATH:$HOME/bin/enblend-enfuse-4.0-mac/:$HOME/bin/hugin/HuginTools/

align_image_stack -m -a aligned- "$@"

enfuse --exposure-weight=0 \
       --saturation-weight=0 \
       --contrast-weight=1 \
       --hard-mask \
       --output=aligned.tif \
       aligned-*

