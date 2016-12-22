use strict;
use warnings;

open my $fh, '<', 'ratings.txt'
	or die "open: $!";
my %all = ();
while (<$fh>) {
	chomp;
	my ($name, @ranks) = /\S+/g;
	$all{$name} = \@ranks;
}

my %score = ();
my $max = 0;

for my $ranks(values %all) {
	for my $i(0..@$ranks-2) {
		my $a = $ranks->[$i];
		for my $j($i+1..@$ranks-1) {
			my $b = $ranks->[$j];
			my $s = ++$score{$a}{$b};
			--$score{$b}{$a};
			$max = $s if $max < $s;
		}
	}
}

print "digraph G {\n";
print "splines=true;\n";
for my $a(keys %score) {
	my $winner = 1;
	my $loser = 1;
	for my $b(keys %{$score{$a}}) {
		my $s = $score{$a}{$b};
		$winner = 0 if $s < 0;
		$loser = 0 if $s > 0;
		next unless $s > 0;
		my $c = 240 * (1.0 - $s / $max);
		$c = sprintf "#%02x%02x%02x", $c, $c, $c;
		my $extra = $s == 0 ? ", dir=none, weight=0" : "";
		print "\"$a\" -> \"$b\" [color=\"$c\"$extra];\n";
	}
	print STDERR "Condorcet winner: $a\n" if $winner;
	print STDERR "Condorcet loser: $a\n" if $loser;
}
print "}\n";
