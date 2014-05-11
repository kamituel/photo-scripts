#!/usr/bin/env bash

TRASH_DIR=$1
DIR=$2

if [ -z "$DIR" ]; then
	echo "Usage: ./delete_raw_with_no_jpeg trash directory"
	exit 1
fi

echo $DIR
echo $TRASH_DIR

for raw in "$DIR""/_raw/"*.ARW; do
	echo -n $raw ": "
	if ! [ -e "$DIR"/`basename "$DIR"/"$raw" .ARW`.JPG ] && ! [ -e "$DIR"/`basename "$DIR"/"$raw" .ARW`.jpg ]; then
		DEST="$TRASH_DIR"/`basename "$DIR"`
		echo -n "moving to " $DEST;
		if ! [ -e "$DEST" ]; then
			mkdir "$DEST"
		fi
		mv "$raw" "$DEST"/
	else
		echo -n "not moving."
	fi
	echo
done
