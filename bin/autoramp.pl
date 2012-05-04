#!/usr/bin/env perl

use strict;
use warnings;

my $ramp_t = undef;
my $ramp_tempo = undef;
my $ramp_target = undef;

my $step = 480; # 8th note

while(<>)
{
	if(!/<tempo time="(\d+)" bph="\d+" tempo="(\d+)"(?: target="(\d+)")?\/>/)
	{
		print;
		next;
	}
	chomp;
	my $t = $1;
	my $tempo = $2;
	my $isramp = $3;

	if(defined $ramp_t)
	{
		my $tt = $ramp_t + $step;
		$ramp_target = $tempo
			if $ramp_target <= 0;
		print STDERR "Ramping from $ramp_tempo to $ramp_target\n";
		while($tt < $t)
		{
			my $ttempo = 3 * int(0.5 + ($ramp_tempo + ($ramp_target - $ramp_tempo) * ($tt - $ramp_t) / ($t - $ramp_t)) / 3);
			print qq{    <tempo time="$tt" bph="@{[ $ttempo * 3 / 5000 ]}" tempo="$ttempo"/>\n};
			$tt += $step;
		}
	}

	if(defined $isramp)
	{
		$ramp_t = $t;
		$ramp_tempo = $tempo;
		$ramp_target = $isramp;
	}
	else
	{
		$ramp_t = undef;
		$ramp_tempo = undef;
		$ramp_target = undef;
	}

	print qq{  <tempo time="$t" bph="@{[ $tempo * 3 / 5000 ]}" tempo="$tempo"/>\n};
}
