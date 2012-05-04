#!/usr/bin/env perl

use strict;
use warnings;

my $ramp_t = undef;
my $ramp_bph = undef;
my $ramp_target = undef;

my $step = 480; # 8th note

while(<>)
{
	if(!/<tempo time="(\d+)" bph="(\d+)" tempo="\d+"(?: target="(\d+)")?\/>/)
	{
		print;
		next;
	}
	chomp;
	my $t = $1;
	my $bph = $2;
	my $isramp = $3;

	if(defined $ramp_t)
	{
		my $tt = $ramp_t + $step;
		$ramp_target = $bph
			if $ramp_target <= 0;
		while($tt < $t)
		{
			my $tbph = 3 * int(0.5 + ($ramp_bph + ($ramp_target - $ramp_bph) * ($tt - $ramp_t) / ($t - $ramp_t)) / 3);
			print qq{    <tempo time="$tt" bph="$tbph" tempo="@{[ $tbph * 5000 / 3 ]}"/>\n};
			$tt += $step;
		}
	}

	if(defined $isramp)
	{
		$ramp_t = $t;
		$ramp_bph = $bph;
		$ramp_target = $isramp;
	}
	else
	{
		$ramp_t = undef;
		$ramp_bph = undef;
		$ramp_target = undef;
	}

	print qq{  <tempo time="$t" bph="$bph" tempo="@{[ $bph * 5000 / 3 ]}"/>\n};
}
