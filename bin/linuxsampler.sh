#!/bin/sh

set -e
killpids=
atexit()
{
	if [ -n "$killpids" ]; then
		kill $killpids
		killpids=
	fi
}
trap atexit EXIT
trap 'exit 1' INT

midifile=$1
gigfile=$2
outfile=$3
extracommands=$4

export JACK_DEFAULT_SERVER=midiconvert.$$
export LSCP_PORT=8888

echo "Finding free port..."
while nc -z localhost $LSCP_PORT; do
	LSCP_PORT=$(($LSCP_PORT+1))
done

echo "Starting jackd..."
if [ -n "$outfile" ]; then
	jackd -d dummy & jackpid=$!
else
	jackd -d alsa & jackpid=$!
fi
killpids=$killpids" $jackpid"
while ! jack_lsp >/dev/null 2>/dev/null; do
	sleep 0.1
done

echo "Starting LinuxSampler..."
linuxsampler --lscp-port $LSCP_PORT & samppid=$!
killpids=$killpids" $samppid"
while ! echo QUIT | ncat -i10 localhost $LSCP_PORT | grep .; do
	sleep 0.1
done

echo "Configuring LinuxSampler..."
{
	cat <<EOF
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
	if [ -n "$extracommands" ]; then
		while :; do
			case "$extracommands" in
				'')
					break
					;;
				*,*)
					echo "${extracommands%%,*}"
					extracommands=${extracommands#*,}
					;;
				*)
					echo "$extracommands"
					break
					;;
			esac
		done;
	fi
	echo QUIT
} | ncat -i10 localhost $LSCP_PORT || true

if [ -n "$outfile" ]; then
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
else
	jack_connect LinuxSampler:0 system:playback_1
	jack_connect LinuxSampler:1 system:playback_2
	jack-smf-player -t -n -a LinuxSampler:midi_in_0 "$midifile"
fi
