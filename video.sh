#!/bin/sh

ffmpeg -y -threads 4 \
       -i "$1" \
       -acodec aac -ar 48000 -ab 128k -ac 2 -strict experimental \
       -vcodec libx264 \
       -bufsize 400000 \
       -b 2800k -bt 1400k -maxrate 2800k \
       -r 30000/1001 \
       "$1.mp4"

#       -vf crop=1920:1080,scale=1920:1080 \
#       -aspect 1920:1080 \
