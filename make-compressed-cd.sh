#!/bin/sh

rm -rf compressed
mkdir -p compressed
tmps=
./list-best-tracks.sh flac | while IFS= read -r track; do
  out=compressed/${track##*/}
  out=${out%.flac}.wav
  sox "$track" -t wav -e floating-point -b 32 "${out}" compand 0.3,1 6:-70,-60,-20 -15 -90 0.2
done
normalize-audio compressed/*.wav
for x in compressed/*.wav; do
  lame --preset standard "$x" "${x%.wav}.mp3"
  rm "$x"
done
