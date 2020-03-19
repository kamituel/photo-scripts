#!/bin/sh

file=$1
lat=""
lat_ref=""
lon=""
lon_ref=""

function usage {
	echo
	echo "Usage:"
	echo "  geotag.sh file.jpg 52.16 N 22.27 E"
	echo
	echo "Error: $1"
	echo
	exit
}


if [ "$#" -eq 3 ]
then
  # Parse coordinates in format: -19.714906, -67.064665
  lat=${2:0:${#2} - 1}
  lon=$3
  if [[ $lat == -* ]]; then
    lat_ref="S"
    lat=${lat:1}
  else
    lat_ref="N"
  fi
  if [[ $lon == -* ]]; then
    lon_ref="W"
    lon=${lon:1}
  else
    lon_ref="E"
  fi
elif [ "$#" -eq 5 ]
then
  # parse_direct_coords
  lat=$2
  lat_ref=$3
  lon=$4
  lon_ref=$5
else
  usage "Invalid number of arguments passed: $#."
fi

echo "LAT=" $lat $lat_ref ", LON=" $lon $lon_ref

if [ ! -f "$file" ]; then
	usage "File does not exist: $file"
fi

if [ "$lat_ref" != "N"  ] && [ "$lat_ref" != "S" ]; then
	usage "Latitude reference should be either 'N' or 'S', was $lat_ref"
fi

if [ "$lon_ref" != "E"  ] && [ "$lon_ref" != "W" ]; then
	usage "Longitude reference should be either 'E' or 'W', was $lon_ref"
fi

exiftool -GPSLongitudeRef=$lon_ref -GPSLongitude=$lon -GPSLatitudeRef=$lat_ref -GPSLatitude=$lat $file
