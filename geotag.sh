#!/bin/sh

function usage {
	echo
	echo "Usage:"
	echo "  geotag.sh file.jpg 52.16 N 22.27 E"
	echo
	echo "Error: $1"
	echo
	exit
}

if [ "$#" -ne 5 ]; then
	usage "Invalid number of arguments passed: $#."
fi

file=$1
lat=$2
lat_ref=$3
lon=$4
lon_ref=$5

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
