#!/usr/bin/env bash

inch="2.54" # cm

width_px=$(exiftool "$1" | perl -ne 'print $1 if /^Image Width\s+:\s(\d+)/')
height_px=$(exiftool "$1" | perl -ne 'print $1 if /^Image Height\s+:\s(\d+)/')

if [ $height_px -gt $width_px ]; then
	tmp=$height_px
	height_px=$width_px
	width_px=$tmp
fi

PURPLE='\033[0;35m'
NO_COLOR='\033[0m'


function print_row {
	label="$1"
	value="$2"

	# Trick to print a nice column.
 	# https://stackoverflow.com/a/4411098	
	line='                     '
	printf "${PURPLE}${label}${NO_COLOR}%s${value}\n" "${line:${#label}}"
}

function px_to_cm {
	px=$1
	dpi=$2
	echo $(bc -l <<< "scale=2; ${px} / ${dpi} * ${inch}")
}

function print_print_dimension {
	dpi=$1
	w=$(px_to_cm $width_px $dpi)
	h=$(px_to_cm $height_px $dpi)
	print_row "   ${dpi} dpi" "${w} x ${h} cm"
}

function round {
	printf %.0f $1 
}

function px_to_dpi {
	px=$1
	cm=$2
	echo $(bc -l <<< "scale=10; ${px} / ${cm} * ${inch}")
}

function print_print_dpi {
	paper_name=$1
	w_cm=$2
	h_cm=$3

	paper_ratio=$(bc -l <<< "scale=10; ${w_cm} / ${h_cm}")
	picture_ratio=$(bc -l <<< "scale=10; ${width_px} / ${height_px}")
	paper_ratio_int=$(round $(bc -l <<< "1000 * $paper_ratio"))
	picture_ratio_int=$(round $(bc -l <<< "1000 * $picture_ratio"))

	if [ $paper_ratio_int -gt $picture_ratio_int ]; then
		w_cm=$(bc -l <<< "scale=10; $h_cm * $picture_ratio")
	else
		h_cm=$(bc -l <<< "scale=10; $w_cm / $picture_ratio")	
	fi
	
	# Both should be the same.
	w_dpi=$(px_to_dpi ${width_px} ${w_cm})
	h_dpi=$(px_to_dpi ${height_px} ${h_cm})

	dpi=$(round $w_dpi)

	print_row "   ${paper_name}" "$dpi dpi"
}

printf "\nFile Info:\n"
print_row "   Dimensions" "${width_px} x ${height_px} px"

printf "\nIf you print at X dpi, print size will be:\n"
print_print_dimension 720
print_print_dimension 360 
print_print_dimension 300
print_print_dimension 220

printf "\nIf you print at X paper size, DPI will be:\n"
print_print_dpi "A4" 29.7 21.0
print_print_dpi "A3" 42.0 29.7
print_print_dpi "A3+" 48.3 32.9
print_print_dpi "A2" 59.4 42.0

printf "\nPaper Sizes:\n"
print_row "   A4" "29.7 x 21.0 cm"
print_row "   A3" "42.0 x 29.7 cm"
print_row "   A3+" "48.3 x 32.9 cm"
print_row "   A2 " "59.4 x 42.0 cm"

echo


