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

fullpath() {
	case "$1" in
		'')
			;;
		/*)
			printf "%s\n" "$1"
			;;
		*)
			printf "%s/%s\n" "$PWD" "$1"
			;;
	esac
}

midifile=`fullpath "$1"`
gigfiles=$2
outfile=`fullpath "$3"`
extracommands=$4

export JACK_DEFAULT_SERVER=midiconvert.$$
export LSCP_PORT=$((($RANDOM + $$ + 8888 - 1024) % 64512 + 1024))
logfile=`mktemp -t midiconvert.XXXXXX`
echo "JACK log file: $logfile"

echo "Finding free port..."
# TODO(rpolzer): Switch to ncat here too.
while nc -z localhost $LSCP_PORT; do
	LSCP_PORT=$(($LSCP_PORT+1))
done

echo "Starting jackd..."
if [ -n "$outfile" ]; then
	${JACKD:-jackd} ${JACKDFLAGS:--r} -n "$JACK_DEFAULT_SERVER" -d dummy -p 32768 >"$logfile" 2>&1 & jackpid=$!
else
	${JACKD:-jackd} ${JACKDFLAGS:--r} -n "$JACK_DEFAULT_SERVER" -d ${JACKDDEVICE:-alsa} >"$logfile" 2>&1 & jackpid=$!
fi
killpids=$killpids" $jackpid"
while ! ${JACK_LSP:-jack_lsp} ${JACK_LSPFLAGS:-} >/dev/null 2>/dev/null; do
	sleep 0.1
done

echo "Starting LinuxSampler..."
${LINUXSAMPLER:-linuxsampler} ${LINUXSAMPLERFLAGS:-} --lscp-port $LSCP_PORT & samppid=$!
killpids=$killpids" $samppid"
while ! echo QUIT | ${NCAT:-ncat} ${NCATFLAGS:--i30} -4 localhost $LSCP_PORT | grep .; do
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
EOF
	ch=0
	for gigfile in $gigfiles; do
		case "$gigfile" in
			*=*)
				vol=${gigfile##*=}
				gigfile=${gigfile%=*}
				;;
			*)
				vol=1.0
				;;
		esac
		gigfile=`fullpath "$gigfile"`
		cat <<EOF
ADD CHANNEL
ADD CHANNEL MIDI_INPUT $ch 0
SET CHANNEL MIDI_INPUT_CHANNEL $ch ALL
EOF
		case "$gigfile" in
			*.gig)
				echo "LOAD ENGINE GIG $ch"
				;;
			*.sfz)
				echo "LOAD ENGINE SFZ $ch"
				;;
			*.sf2)
				echo "LOAD ENGINE SF2 $ch"
				;;
		esac
		cat <<EOF
SET CHANNEL VOLUME $ch $vol
SET CHANNEL MIDI_INSTRUMENT_MAP $ch NONE
SET CHANNEL AUDIO_OUTPUT_DEVICE $ch 0
LOAD INSTRUMENT '$gigfile' 0 $ch
EOF
		ch=$((ch + 1))
	done
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
} | tee /dev/stderr | ${NCAT:-ncat} ${NCATFLAGS:--i30} -4 localhost $LSCP_PORT || true

while ! ${JACK_LSP:-jack_lsp} ${JACK_LSPFLAGS:-} 2>/dev/null | grep LinuxSampler:1 >/dev/null; do
	sleep 0.1
done

if [ -n "$outfile" ]; then
	(
		: > "$outfile"
		${JACK_CAPTURE:-jack_capture} ${JACK_CAPTUREFLAGS:-} --daemon -c 2 -p LinuxSampler:0 -p LinuxSampler:1 "$outfile" & cappid=$!
		#${JACK_REC:-jack_rec} ${JACK_RECFLAGS:-} -f "$outfile" LinuxSampler:0 LinuxSampler:1 & cappid=$!
		# wait till there is more than just the WAV header in the outfile
		while [ `stat -c %s "$outfile" 2>/dev/null || echo 0` -lt 2048 ]; do
			sleep 0.1
		done
		echo "Playing..."
		${JACK_SMF_PLAYER:-jack-smf-player} ${JACK_SMF_PLAYERFLAGS:-} -t -n -a LinuxSampler:midi_in_0 "$midifile"
		kill $cappid
		wait
	)
else
	${JACK_CONNECT:-jack_connect} ${JACK_CONNECTFLAGS:-} LinuxSampler:0 system:playback_1
	${JACK_CONNECT:-jack_connect} ${JACK_CONNECTFLAGS:-} LinuxSampler:1 system:playback_2
	${JACK_SMF_PLAYER:-jack-smf-player} ${JACK_SMF_PLAYERFLAGS:-} -t -n -a LinuxSampler:midi_in_0 "$midifile"
fi

atexit
trap - EXIT
if grep -i xrun "$logfile"; then
	exit 1
fi
rm -f "$logfile"
