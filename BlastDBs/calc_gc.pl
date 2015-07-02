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
	my $seq = $_;
	my $gc = $seq =~ tr/GCgc/GCGC/;
	my $gc_content = $gc / length($_);
	print "$gc_content\n";
    }
}
close(IN)
