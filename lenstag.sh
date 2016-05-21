#!/bin/bash


function usage {
  echo "Usage: "
  echo "  ./lenstag.sh LENS-MODEL APERTURE photo-file"
}

# Read lens data
case "$1" in
"zeiss-cy-50/1.4")
  lens="Carl Zeiss Planar T* 50mm f/1.4 (C/Y)"
  focal_length="50"
  ;;
*)
  echo "ERROR: missing or invalid lens name"
  usage
  exit 1
  ;;
esac

# Read aperture data
aperture="$2"
if [ -z ${aperture+x} ]; then
  echo "ERROR: missing aperture value"
  usage
  exit 2
fi

# Read file name
file="$3"
if [ -z ${aperture+x} ]; then
  echo "ERROR: missing file name"
  usage
  exit 3
fi

# Tag a lens
exiftool \
  -Lens="$lens" \
  -LensModel="$lens" \
  -FocalLength="$focal_length" \
  -ApertureValue="$aperture" \
  -FNumber="$aperture" \
  "$3"
