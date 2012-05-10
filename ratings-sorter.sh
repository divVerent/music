#!/bin/sh

s=$1
t=$2

order=
while read -r S ORDER; do
	[ x"$S" = x"$s" ] || continue
	order=$ORDER
done < ratings.txt

if [ -z "$order" ]; then
	echo "$1 not found"
fi

decide_real()
{
	dra=$1
	drb=$2
	ln -snf "$s-$dra.mp3" a.mp3
	ln -snf "$s-$drb.mp3" b.mp3

	drs=-1
	while :; do
		mplayer a.mp3 b.mp3
		echo "Which was better? (a/b)"
		read -r ab
		case "$ab" in
			a)
				drs=0
				break
				;;
			b)
				drs=1
				break
				;;
		esac
	done

	rm -f a.mp3 b.mp3

	return $drs
}

# 0: ok
# 1: please swap
decide()
{
	da=$1
	db=$2
	if [ $(($RANDOM % 2)) -eq 0 ]; then
		decide_real "$da" "$db"
	else
		! decide_real "$db" "$da"
	fi
}

# 0: did swap
# 1: didn't swap
compare_and_swap()
{
	p=$1
	set -- $order
	n=$#

	# won't swap if too high/low
	if [ $p -lt 0 ]; then
		return 1
	fi
	if [ $p -ge $(($n - 1)) ]; then
		return 1
	fi

	pre=
	post=
	i=0
	while [ $i -lt $n ]; do
		if [ $i -eq $p ]; then
			a=$1
		elif [ $i -eq $(($p+1)) ]; then
			b=$1
		elif [ $i -lt $p ]; then
			pre="$pre$1 "
		else # elif [ $i -gt $(($p+1)) ]; then
			post="$post $1"
		fi
		i=$(($i+1))
		shift
	done

	#echo "DECIDE $pre  ($a <=> $b)  $post"

	if decide "$a" "$b"; then
		order="$pre$a $b$post"
		return 1
	else
		order="$pre$b $a$post"
		return 0
	fi
}

set -- $order
if [ -n "$t" ]; then
	tpos=0
	for X in "$@"; do
		if [ x"$X" = x"$t" ]; then
			break
		fi
		tpos=$(($tpos+1))
	done
	if [ $tpos -ge $# ]; then
		echo "Not found"
		exit 1
	fi

	if [ $(($RANDOM % 2)) -eq 0 ]; then
		if compare_and_swap "$tpos"; then
			# we swapped. Continue upwards
			# INVARIANT: ours is A
			while tpos=$(($tpos + 1)); compare_and_swap "$tpos"; do
				:
			done
		else
			# we didn't swap. Continue downwards
			# INVARIANT: ours is B
			while tpos=$(($tpos - 1)); compare_and_swap "$tpos"; do
				:
			done
		fi
	else
		tpos=$(($tpos - 1))
		if compare_and_swap "$tpos"; then
			# we didn't swap. Continue downwards
			# INVARIANT: ours is B
			while tpos=$(($tpos - 1)); compare_and_swap "$tpos"; do
				:
			done
		else
			# we swapped. Continue upwards
			# INVARIANT: ours is A
			while tpos=$(($tpos + 1)); compare_and_swap "$tpos"; do
				:
			done
		fi
	fi
else
	compare_and_swap $(($RANDOM % ($# - 1)))
fi

while read -r S ORDER; do
	if [ x"$S" = x"$s" ]; then
		echo "$s $order"
	else
		echo "$S $ORDER"
	fi
done < ratings.txt > ratings-new.txt
mv ratings-new.txt ratings.txt
