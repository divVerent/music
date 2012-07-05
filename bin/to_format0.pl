#!/usr/bin/env perl

use strict;
use warnings;
use MIDI::Opus;
use MIDI::Track;
use MIDI::Event;
use POSIX;

my ($filename, $outfilename, $extratime_pre, $extratime_post, $collapse_channels, $cnt, $drop_silence) = @ARGV;
my $opus = MIDI::Opus->new({from_file => $filename});

# where is channel stored in which events?
my %chanpos = (
	note_off => 2,
	note_on => 2,
	key_after_touch => 2,
	control_change => 2,
	patch_change => 2,
	channel_after_touch => 2,
	pitch_wheel_change => 2
);

sub abstime(@)
{
	my $t = 0;
	return map { [$_->[0], $t += $_->[1], @{$_}[2..(@$_-1)]]; } @_;
}

sub reltime(@)
{
	my $t = 0;
	return map { my $tsave = $t; $t = $_->[1]; [$_->[0], $t - $tsave, @{$_}[2..(@$_-1)]]; } @_;
}

sub note($)
{
	my $n = $_[0] - 60;
	my $n_abs = ($n + 60) % 12;
	my $n_oct = POSIX::floor($n / 12);
	my $n_name = [qw[C C+ D D+ E F F+ G G+ A A+ B]]->[$n_abs];
	return "$n_name$n_oct";
}

# map all to channel 0 and to a single track
$opus->format(0);
my @outevents = reltime sort { ($a->[1] <=> $b->[1]) or (($a->[0] eq 'note_on') <=> ($b->[0] eq 'note_on')) } map { abstime $_->events() } $opus->tracks();
my %notehash = ();
my $t = 0;
my $tempo = 500000;

if($drop_silence)
{
	for my $e(@outevents)
	{
		$e->[1] = 0;
		last
			if $e->[0] =~ /^note_/;
	}
	for my $e(reverse @outevents)
	{
		last
			if $e->[0] =~ /^note_/;
		$e->[1] = 0;
	}
}

@outevents = map { @outevents } 1..$cnt
	if $cnt;

if($extratime_pre)
{
	# calculate delta time for 5 seconds
	# tempo is encoded as microseconds per quarter note
	my $time_per_tick = $tempo * 0.000001 / $opus->ticks();
	my $dtime = int($extratime_pre / $time_per_tick);

	# add a redundant note-off at the end 5 seconds later to let notes cool down
	print STDERR "Using $dtime ticks pre-delay\n";
	unshift @outevents, ['note_off', $dtime, 0, 0, 0];
	#unshift @outevents, ['text_event', $dtime, ''];
}

for my $e(@outevents)
{
	$t += $e->[1];
	my $p = $chanpos{$e->[0]};
	$e->[$p] = 0
		if defined $p and $collapse_channels;
	if($e->[0] eq 'note_on')
	{
		warn "Note @{[note $e->[3]]} is played twice at @{[ $t * 2 ]}\n" # times 2 for rosegarden units
			if $notehash{$e->[3]}++;
	}
	if($e->[0] eq 'note_off')
	{
		delete $notehash{$e->[3]}
	}
	if($e->[0] eq 'set_tempo')
	{
		$tempo = $e->[2];
	}
}
warn "Notes still on at end: " .  join ' ', keys %notehash
	if keys %notehash;

if($extratime_post)
{
	# calculate delta time for 5 seconds
	# tempo is encoded as microseconds per quarter note
	my $time_per_tick = $tempo * 0.000001 / $opus->ticks();
	my $dtime = int($extratime_post / $time_per_tick);

	# add a redundant note-off at the end 5 seconds later to let notes cool down
	print STDERR "Using $dtime ticks post-delay\n";
	push @outevents, ['note_off', $dtime, 0, 0, 0];
	#push @outevents, ['text_event', $dtime, ''];
}

$opus->tracks([$opus->tracks()]->[0]);
[$opus->tracks()]->[0]->events(@outevents);

$opus->write_to_file($outfilename);
