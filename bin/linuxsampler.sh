#!/bin/sh

set -e
killpids=
atexit()
{
	if [ -n "$killpids" ]; then
		kill $killpids || true
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
export LSCP_PORT=$((($RANDOM + $$ + 8888 - 1024) % 64512 + 1024))

echo "Finding free port..."
while nc -z localhost $LSCP_PORT; do
	LSCP_PORT=$(($LSCP_PORT+1))
done

echo "Starting jackd..."
if [ -n "$outfile" ]; then
	${JACKD:-jackd} ${JACKDFLAGS:--r} -n "$JACK_DEFAULT_SERVER" -d dummy & jackpid=$!
else
	${JACKD:-jackd} ${JACKDFLAGS:--r} -n "$JACK_DEFAULT_SERVER" -d ${JACKDDEVICE:-alsa} & jackpid=$!
fi
killpids=$killpids" $jackpid"
while ! ${JACK_LSP:-jack_lsp} ${JACK_LSPFLAGS:-} >/dev/null 2>/dev/null; do
	sleep 0.1
done

echo "Starting LinuxSampler..."
${LINUXSAMPLER:-linuxsampler} ${LINUXSAMPLERFLAGS:-} --lscp-port $LSCP_PORT & samppid=$!
killpids=$killpids" $samppid"
while ! echo QUIT | ${NCAT:-ncat} ${NCATFLAGS:--i10} localhost $LSCP_PORT | grep .; do
	sleep 0.1
done

echo "Configuring LinuxSampler..."
{
	cat <<EOF
RESET
SET VOLUME 0.125
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
EOF
	case "$gigfile" in
		*.gig)
			echo "LOAD ENGINE GIG 0"
			;;
		*.sfz)
			echo "LOAD ENGINE SFZ 0"
			;;
		*.sf2)
			echo "LOAD ENGINE SF2 0"
			;;
	esac
	cat <<EOF
SET CHANNEL VOLUME 0 1.0
SET CHANNEL MIDI_INSTRUMENT_MAP 0 NONE
SET CHANNEL AUDIO_OUTPUT_DEVICE 0 0
LOAD INSTRUMENT '$gigfile' 0 0
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
} | tee /dev/stderr | ${NCAT:-ncat} ${NCATFLAGS:--i10} localhost $LSCP_PORT || true

if [ -n "$outfile" ]; then
	(
		: > "$outfile"
		${JACK_CAPTURE:-jack_capture} ${JACK_CAPTUREFLAGS:-} --daemon -c 2 -p LinuxSampler:0 -p LinuxSampler:1 "$outfile" & cappid=$!
		# wait till there is more than just the WAV header in the outfile
		while [ `stat -c %s "$outfile" 2>/dev/null || echo 0` -lt 2048 ]; do
			sleep 0.1
		done
		${JACK_SMF_PLAYER:-jack-smf-player} ${JACK_SMF_PLAYERFLAGS:-} -t -n -a LinuxSampler:midi_in_0 "$midifile"
		kill $cappid
		wait
	)
else
	${JACK_CONNECT:-jack_connect} ${JACK_CONNECTFLAGS:-} LinuxSampler:0 system:playback_1
	${JACK_CONNECT:-jack_connect} ${JACK_CONNECTFLAGS:-} LinuxSampler:1 system:playback_2
	${JACK_SMF_PLAYER:-jack-smf-player} ${JACK_SMF_PLAYERFLAGS:-} -t -n -a LinuxSampler:midi_in_0 "$midifile"
fi
