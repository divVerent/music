#!/bin/sh

midifile=$1
gigfile=$2
outfile=$3

export JACK_DEFAULT_SERVER=midiconvert.$$
export LSCP_PORT=8888

echo "Finding free port..."
while nc -z localhost $LSCP_PORT; do
	LSCP_PORT=$(($LSCP_PORT+1))
done

echo "Starting jackd..."
jackd -d dummy & jackpid=$!
while ! jack_lsp >/dev/null 2>/dev/null; do
	sleep 0.1
done

echo "Starting LinuxSampler..."
linuxsampler --lscp-port $LSCP_PORT & samppid=$!
while ! nc -z localhost $LSCP_PORT; do
	sleep 0.1
done

echo "Configuring LinuxSampler..."
nc -v localhost $LSCP_PORT <<EOF
RESET
SET VOLUME 0.10
CREATE MIDI_INPUT_DEVICE JACK NAME='LinuxSampler'
SET MIDI_INPUT_PORT_PARAMETER 0 0 NAME='midi_in_0'
CREATE AUDIO_OUTPUT_DEVICE JACK ACTIVE=true CHANNELS=2 SAMPLERATE=48000 NAME='LinuxSampler'
SET AUDIO_OUTPUT_CHANNEL_PARAMETER 0 0 NAME='0'
SET AUDIO_OUTPUT_CHANNEL_PARAMETER 0 1 NAME='1'
REMOVE MIDI_INSTRUMENT_MAP ALL
ADD CHANNEL
SET CHANNEL MIDI_INPUT_DEVICE 0 0
SET CHANNEL MIDI_INPUT_PORT 0 0
SET CHANNEL MIDI_INPUT_CHANNEL 0 ALL
LOAD ENGINE GIG 0
SET CHANNEL VOLUME 0 1.0
SET CHANNEL MIDI_INSTRUMENT_MAP 0 NONE
SET CHANNEL AUDIO_OUTPUT_DEVICE 0 0
LOAD INSTRUMENT '$gigfile' 0 0
QUIT
EOF
while ! jack_lsp | grep LinuxSampler:0; do
	sleep 0.1
done

(
 	rm -f "$outfile"
	jack_capture --daemon -b 16 -c 2 -p LinuxSampler:0 -p LinuxSampler:1 "$outfile" & cappid=$!
	# wait till there is more than just the WAV header in the outfile
	while [ `stat -c %s "$outfile" 2>/dev/null || echo 0` -lt 2048 ]; do
		sleep 0.1
	done
	jack-smf-player -t -n -a LinuxSampler:midi_in_0 "$midifile"
	kill $cappid
	wait
)

kill $samppid
kill $jackpid
