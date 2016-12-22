#!/bin/sh

set -ex

rm -rf replaygain
for album in $(
	for f in */*.ogg */*.flac */*.mp3; do
		[ -f "$f" ] || continue
		echo "${f#*-}"
	done | sort -u
); do
	set -- */*-"$album"
	bs1770gain -o "replaygain/" --replaygain "$@"
	for t in "$@"; do
		mv -v "replaygain/${t##*/}" "$t"
	done
	rmdir replaygain
done
