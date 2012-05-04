#!/usr/bin/env perl

use strict;
use warnings;
use MIDI;
use MIDI::Opus;
use POSIX;

my ($filename, $outfilename) = @ARGV;
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
for my $e(@outevents)
{
	$t += $e->[1];
	my $p = $chanpos{$e->[0]};
	$e->[$p] = 0
		if defined $p;
	if($e->[0] eq 'note_on')
	{
		warn "Note @{[note $e->[3]]} is played twice at @{[ $t * 2 ]}\n" # times 2 for rosegarden units
			if $notehash{$e->[3]}++;
	}
	if($e->[0] eq 'note_off')
	{
		delete $notehash{$e->[3]}
	}
}
$opus->tracks([$opus->tracks()]->[0]);
[$opus->tracks()]->[0]->events(@outevents);

$opus->write_to_file($outfilename);
