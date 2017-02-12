package CASC::QC;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(check_threads check_fasta);
%EXPORT_TAGS = ( DEFAULT => [qw(&check_threads)],
                 Both    => [qw(&check_threads &check_fasta)]);

sub check_threads
{
    my $nseqs = $_[0];
    my $nthreads = $_[1];
    if ($nthreads < 1) { die "\n\n ERROR: The number of threads you select must be >1. You selected $nthreads\n\n";    }
    if ($nseqs < $nthreads) {
	$nthreads = $nseqs;
	print " WARNING: You cannot use more CPUs than there are sequences. Dont worry, ncpus has been adjusted to $nthreads\n";
    }
    return $nthreads;
}

sub check_fasta
{
    my $infile = $_[0];
    my $nseqs = 0;
    open(IN,"<$infile") || die "\n\n ERROR: Cannot find or open the input file: $infile\n\n";
    while(<IN>) {
        chomp;
        unless ($_ =~ m/^>/) {
            my $seq_string = $_;
            my $valid_bases = $seq_string =~ tr/ACGTURYKMSWBDHVNXacgturykmswbdhvnx/ACGTURYKMSWBDHVNXacgturykmswbdhvnx/;
            if ($valid_bases != length($_)) { die "\n\n ERROR: It appears your FASTA file contains non-nucleotide charecters\n\n\n Offending sequence:\n$_\n\n\n";}
        }
    }
    close(IN);
}

1;
