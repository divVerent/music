#!/usr/bin/env perl

use strict;
use warnings;
use MIDI::Opus;
use MIDI::Track;
use MIDI::Event;
use POSIX;

my ($filename, $outfilename, $mode, $strength_abs, $strength_rel) = @ARGV;
my $opus = MIDI::Opus->new({from_file => $filename});

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

my $ticksperquarter = $opus->ticks();
my @tempi = (); # list of start tick, time per tick pairs (calculated as seconds per quarter / ticks per quarter)
my $tick;
$tick = 0;
for($opus->tracks_r()->[0]->events())
{
	$tick += $_->[1];
	if($_->[0] eq 'set_tempo')
	{
		push @tempi, [$tick, $_->[2] * 0.000001 / $ticksperquarter];
	}
}
sub tick2sec($)
{
	my ($tick) = @_;
	my $sec = 0;
	my $curtempo = [0, 0.5 / $ticksperquarter];
	for(@tempi)
	{
		if($_->[0] < $tick)
		{
			# this event is in the past
			# we add the full time since the last one then
			$sec += ($_->[0] - $curtempo->[0]) * $curtempo->[1];
		}
		else
		{
			# if this event is in the future, we break
			last;
		}
		$curtempo = $_;
	}
	$sec += ($tick - $curtempo->[0]) * $curtempo->[1];
	return $sec;
}
sub sec2tick($) {
	my ($sec) = @_;
	my $curtempo = [0, 0.5 / $ticksperquarter];
	my $t = 0;
	for(@tempi)
	{
		my $start = $t + ($_->[0] - $curtempo->[0]) * $curtempo->[1];
		if($start < $sec)
		{
			# this event is in the past
			$t = $start;
		}
		else
		{
			# if this event is in the future, we break
			last;
		}
		$curtempo = $_;
	}
	my $tick = $curtempo->[0] + ($sec - $t) / $curtempo->[1];
	return $tick;
}

my %dist = (
	# TODO add more distributions - at least gaussian and pink
	uniform => sub { 1.0 - 2.0 * rand },
);

sub jitter($) {
	my ($tick) = @_;
	my $r = $dist{$mode}->();
	$tick = sec2tick(tick2sec($tick) + $r * $strength_abs);
	$tick += $r * $strength_rel * $ticksperquarter;
	return int $tick;
}

# TODO We assume here that we can safely jitter each track independently.
# This is not true if multiple tracks use the same MIDI channel!
# Dependency handling: we allow rearranging events of the same type.
for ($opus->tracks()) {
	my @events;
	my @eventgroup;
	my $mintime = 0;
	for my $ev(abstime $_->events()) {
		my ($cmd, $time, @data) = @$ev;
		if (@eventgroup and $cmd ne $eventgroup[-1][0]) {
			# Flush the event group.
			@eventgroup = sort { $a->[1] <=> $b->[1] } @eventgroup;
			$mintime = $eventgroup[-1][1];
			push @events, @eventgroup;
			@eventgroup = ();
		}
		$time = jitter $time;
		$time = $mintime
			if $time < $mintime;
		push @eventgroup, [$cmd, $time, @data];
	}
	# Flush the event group.
	@eventgroup = sort { $a->[1] <=> $b->[1] } @eventgroup;
	push @events, @eventgroup;
	$_->events(reltime @events);
}

$opus->write_to_file($outfilename);
