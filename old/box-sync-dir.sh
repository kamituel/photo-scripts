#!/bin/bash

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CP_CMD="ruby2.0 $SELF_DIR/box-cp.rb"
BOX_ACCOUNT_NAME="$1"
SKIP_N="$3"
if [ -z "$SKIP_N" ]; then
  SKIP_N=0
fi

PARENT_DIR="$2"

for DIR in "$PARENT_DIR"/*; do

if [ $SKIP_N -gt 0 ]; then
  SKIP_N=$((SKIP_N-1))
  continue
fi

echo "$DIR";
DIR_NAME=$(basename "$DIR")

echo $DIR
echo $DIR_NAME

DIR_REMOTE_CONTENTS=$($CP_CMD $BOX_ACCOUNT_NAME ls "/$DIR_NAME")
FILE_COUNT=$?

if [ $FILE_COUNT -ge 0 ]; then
    echo "Folder already exists on remote account"
else
    echo "Folder does not exist, creating"
fi

# Check if the folder already exists on remote location. Create if not.
case "${ALL[@]}" in 
  *"$DIR_NAME"*) 
    ;; 
  *) 
    $CP_CMD $BOX_ACCOUNT_NAME mkdir / "$DIR_NAME"
    ;;
esac

for i in "$DIR"/*; do
  filename=$(basename "$i")   

  if [ -f "$i" ]; then

    # Check if file exists. If so, do not push it again
    case "${DIR_REMOTE_CONTENTS[@]}" in
      *"$filename"*)
        #echo "already exists in remote location, skipped"
        ;;
      *)
        echo "$filename [F] copying"
        $CP_CMD $BOX_ACCOUNT_NAME push "$i" "/$DIR_NAME"
        ;;
    esac
  else
    echo "$filename [D] skipped"
    continue
  fi
done
done
