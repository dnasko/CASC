#!/usr/bin/perl -w
use strict;

my $infile = $ARGV[0];
my $header;

open(IN,"<$infile") || die "\n Cannot open the file: $infile\n";
while(<IN>) {
    chomp;
    if ($_ =~ m/^>/) {
	$header = $_;
    }
    else {
	my @a = split(//, $_);
	my $compressed = $a[0];
	for (my $i=1; $i<scalar(@a); $i++) {
	    unless ($a[$i] eq $a[$i-1]) {
		$compressed = $compressed . $a[$i];
	    }
	}
	my $rate = length($compressed) / length($_);
	my $seq = $_;
	my $gc = $seq =~ tr/GCgc/GCGC/;
	my $gc_content = $gc / length($_);
	print $rate . "\t" . $gc_content . "\n";
	# print ">" .  $rate . "\n" . $_ . "\n";
	# print $rate . "\n";
	# if ($rate >= 0.9 || $rate <= 0.4) {
	#     print ">" .  $rate . "\n" . $_ . "\n";
	# }
    }
}
close(IN)
