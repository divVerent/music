#!/usr/bin/env perl

use strict;
use warnings;

my ($mmp, $mmpo) = @ARGV;

open my $fh, "<", $mmp
	or die "<$mmp: $!";
my $data = do { undef local $/; <$fh>; };
close $fh;

my $instrument = do { undef local $/; <STDIN>; };
$instrument =~ /<instrumenttrack/
	or die "Not an instrument";

$data =~ s/(.*)<instrumenttrack.*?>.*?<\/instrumenttrack>/$1$instrument/s;

open $fh, ">", $mmpo
	or die ">$mmpo: $!";
print $fh $data
	or die ">$mmpo print: $!";
close $fh
	or die ">$mmpo close: $!";
