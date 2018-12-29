#!/bin/sh

ext=${1:-mp3}

while read -r s best _; do
	echo "$s-$best.$ext"
done <ratings.txt
