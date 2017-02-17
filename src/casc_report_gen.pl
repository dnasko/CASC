#!/usr/bin/perl -w

# MANUAL FOR casc_report_gen.pl

=pod

=head1 NAME

casc_report_gen.pl -- creates the casc report files

=head1 SYNOPSIS

 casc_report_gen.pl --blastx /Path/to/blastx.lookup --blastn /Path/to/blastn.lookup --mcrt /Path/to/mCRT.output --spacer /Path/to/spacer.fasta --repeat /Path/to/repeat.fasta --outdir /Path/to/outdir/ [--conservative]
                     [--help] [--manual]

=head1 DESCRIPTION

 Does all of the nasty parsing needed to organize CASC outputs.
No need for a human to run this, the CASC script will call this
script.
 
=head1 OPTIONS

=over 3

=item B<-x, --blastx>=FILENAME

Input file in lookup format. (Required) 

=item B<-n, --blastn>=FILENAME

Input file in lookup format. (Required)

=item B<-c, --mcrt>=FILENAME

Input file in lookup format. (Required)

=item B<-s, --spacer>=FILENAME

Input spacer fasta file. (Required)

=item B<-r, --repeat>=FILENAME

Input repeat fasta file. (Required)

=item B<-o, --outdir>=FILENAME

Output file directory. (Required) 

=item B<-co, --conservative>

Whether this was a conservative run or not. (Default = Liberal)

=item B<-h, --help>

Displays the usage message.  (Optional) 

=item B<-m, --manual>

Displays full manual.  (Optional) 

=back

=head1 DEPENDENCIES

Requires the following Perl libraries.



=head1 AUTHOR

Written by Daniel Nasko, 
Center for Bioinformatics and Computational Biology, University of Delaware.

=head1 REPORTING BUGS

Report bugs to dnasko@udel.edu

=head1 COPYRIGHT

Copyright 2015 Daniel Nasko.  
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.  
This is free software: you are free to change and redistribute it.  
There is NO WARRANTY, to the extent permitted by law.  

Please acknowledge author and affiliation in published work arising from this script's 
usage <http://bioinformatics.udel.edu/Core/Acknowledge>.

=cut


use strict;
use Getopt::Long;
use File::Basename;
use Pod::Usage;
use CASC::Parsing qw(:Both);
use CASC::Utilities qw(:Both);
use Cwd 'abs_path';

#ARGUMENTS WITH NO DEFAULT
my($infile,$blastx,$blastn,$mcrt,$spacer,$repeat,$outdir,$stats,$conservative,$help,$manual);

GetOptions (	
                "i|infile=s"    =>      \$infile,
                "x|blastx=s"	=>	\$blastx,
                "n|blastn=s"    =>      \$blastn,
                "c|mcrt=s"      =>      \$mcrt,
                "s|spacer=s"    =>      \$spacer,
                "r|repeat=s"    =>      \$repeat,
                "o|outdir=s"	=>	\$outdir,
                "st|stats=s"    =>      \$stats,
                "co|conservative" => \$conservative,
		"h|help"	=>	\$help,
		"m|manual"	=>	\$manual);

# VALIDATE ARGS
pod2usage(-verbose => 2)  if ($manual);
pod2usage( {-exitval => 0, -verbose => 2, -output => \*STDERR} )  if ($help);
pod2usage( -msg  => "\n\n ERROR!  Required argument --infile not found.\n\n", -exitval => 2, -verbose => 1)  if (! $infile );
pod2usage( -msg  => "\n\n ERROR!  Required argument --blastx not found.\n\n", -exitval => 2, -verbose => 1)  if (! $blastx );
pod2usage( -msg  => "\n\n ERROR!  Required argument --blastn not found.\n\n", -exitval => 2, -verbose => 1)  if (! $blastn );
pod2usage( -msg  => "\n\n ERROR!  Required argument --mcrt not found.\n\n", -exitval => 2, -verbose => 1)  if (! $mcrt );
pod2usage( -msg  => "\n\n ERROR!  Required argument --spacer not found.\n\n", -exitval => 2, -verbose => 1)  if (! $spacer );
pod2usage( -msg  => "\n\n ERROR!  Required argument --repeat not found.\n\n", -exitval => 2, -verbose => 1)  if (! $repeat );
pod2usage( -msg  => "\n\n ERROR!  Required argument --outdir not found.\n\n", -exitval => 2, -verbose => 1)  if (! $outdir);
pod2usage( -msg  => "\n\n ERROR!  Required argument --stats not found.\n\n", -exitval => 2, -verbose => 1)  if (! $stats);

my %Blastx;
my %Blastn;
my %Blastn2;
my %Bonafide;
my $nstats = 0;

open(IN,"<$blastx") || die "\n Cannot open the blastx file: $blastx\n";
while(<IN>) {
    chomp;
    my @a = split(/\t/, $_);
    $Blastx{$a[0]} = 1;
}
close(IN);

open(IN,"<$blastn") || die "\n Cannot open the blastn file: $blastn\n";
while(<IN>) {
    chomp;
    my ($r,$a) = parse_header($_);
    $Blastn{$r}{$a} = 1;
    $Blastn2{$r}{$a} = 1;
}
close(IN);

my %ArrayPositions = parse_mcrt($mcrt); ## $ArrayPositions{seq}{array#}{'start'} = blah;

my %SpacerStats = parse_spacer_stats($spacer); ## $SpacerStats{seq}{array#}{'avg'} = blah; $SpacerStats{seq}{array#}{'std'} = blah; $SpacerStats{seq}{array#}{'n'} = blah;

my @Order = spacer_order($spacer);

open(OUT,">$outdir/" . get_basename($spacer) . ".results.txt" ) || die "\n Error cannot open file " . "$outdir/" . get_basename($spacer) . ".results.txt";
print OUT "#seq_id\tarray_id\tspacers\tarray_start\tarray_stop\tmean_spacer_len\tstddev_spacer_len\tbonafide\tcode\n";
foreach my $i (@Order) {
    my @a = split(/_/, $i);
    my $array_no = pop(@a);
    my $root = join("_", @a);
    my $code;
    if (exists $Blastx{$root}) { $code = "1"; }
    else { $code = "0"; }
    if (exists $Blastn{$root}{$array_no}) { $code = $code . "1"; }
    else { $code = $code . "0"; }
    if (exists $SpacerStats{$root}{$array_no}{'avg'} && exists $SpacerStats{$root}{$array_no}{'std'}) {
	if ($SpacerStats{$root}{$array_no}{'avg'} > 19 && $SpacerStats{$root}{$array_no}{'std'} <= 2) {
	    $code = $code . "1";
	    $nstats++;
	}
	else {
	    $code = $code . "0";
	}
    }
    else { die "\n Error: Missing the spacer stats for $root\n"; }
    my $valid = "error";
    if ($conservative && bin2dec($code) > 1) { $valid = "true"; }
    if (bin2dec($code) > 0) { $valid = "true"; }
    if ($conservative && bin2dec($code) <= 1) { $valid = "false"; }
    if (bin2dec($code) == 0) { $valid = "false"; }
    print OUT $root . "\t" . $array_no . "\t" . 
	$SpacerStats{$root}{$array_no}{'n'} . "\t" . 
	$ArrayPositions{$root}{$array_no}{'start'} . "\t" . 
	$ArrayPositions{$root}{$array_no}{'stop'} . "\t" . 
	$SpacerStats{$root}{$array_no}{'avg'} . "\t" . 
	$SpacerStats{$root}{$array_no}{'std'} . "\t" . 
	$valid .  "\t" . bin2dec($code) . "\n";
    if ($valid eq "true") { $Bonafide{$root}{$array_no} = 1; }
}
close(OUT);


my $h = "";
open(BON,">$outdir/" . get_basename($spacer) . ".bonafide.spacers.fasta" ) || die "\n Error cannot open file " . "$outdir/" . get_basename($spacer) . ".bonafide.spacers.fasta";
open(NBON,">$outdir/" . get_basename($spacer) . ".non-bonafide.spacers.fasta" ) || die "\n Error cannot open file " . "$outdir/" . get_basename($spacer) . ".non-bonafide.spacers.fasta";
open(IN,"<$spacer") || die "\n Cannot open the file: $spacer\n";
while(<IN>) {
    chomp;
    if ($_ =~ m/^>/) {
	$h = $_;
    }
    else {
	my ($base,$array_no) = parse_header($h);
	if (exists $Bonafide{$base}{$array_no}) {
	    print BON $h . "\t" . $_ . "\n";
	}
	else {
	    print NBON $h . "\t" . $_ . "\n";
	}
    }
}
close(IN);
close(BON);
close(NBON);

open(BON,">$outdir/" . get_basename($spacer) . ".bonafide.repeats.fasta" ) || die "\n Error cannot open file " . "$outdir/" . get_basename($spacer) . ".bonafide.repeats.fasta";
open(NBON,">$outdir/" . get_basename($spacer) . ".non-bonafide.repeats.fasta" ) || die "\n Error cannot open file " . "$outdir/" . get_basename($spacer) . ".non-bonafide.repeats.fasta";
open(IN,"<$repeat") || die "\n Cannot open the file: $repeat\n";
while(<IN>) {
    chomp;
    if ($_ =~ m/^>/) {
	$h = $_;
    }   
    else {
	my ($base,$array_no) = parse_header($h);
    	if (exists $Bonafide{$base}{$array_no}) {
            print BON $h . "\t"	. $_ . "\n";
        }
        else {
            print NBON $h . "\t" . $_ . "\n";
	}
    }
}
close(IN);
close(BON);
close(NBON);


## Printing the markdown report
my $mode = "Liberal";
if ($conservative) {$mode = "Conservative"; }
my @Stats = split(/,/, $stats);
my $mean_read = Round($Stats[0] / $Stats[1], 0);
my $nbonafide = keys %Bonafide;
my $ncas = keys %Blastx;
my $nrepeat = keys %Blastn2;
my $narrays = keys %ArrayPositions;
my $percent = Round(($nbonafide / $narrays)*100, 0);
$percent = $percent . "%";

open(OUT,">$outdir/" . get_basename($spacer) . ".report.md" ) || die "\n Error cannot open file " . "$outdir/" . get_basename($spacer) . ".report.md";
print OUT "CASC Report\n===========\n
### Input Summary

- Input File: " . abs_path($infile) . "
- Number of Sequences = " . $Stats[1] . "
- Number of Bases = " . $Stats[0] . "
- Bases per Sequence = " . $mean_read . "
- Mode = " . $mode . "

### CRISPR Identification
- Putative CRISPR arrays found = " . $narrays . "
- Bona fide CRISPR arrays = " . $nbonafide . " ($percent)
- Arrays with Cas protein upstream = " . $ncas . "
- Arrays with repeats matching known CRISPR repeats = " . $nrepeat . "
- Arrays with proper statistics (liberal mode only) = " . $nstats . "\n";
close(OUT);


## Subroutines
sub parse_header
{
    my $s = $_[0];
    $s =~ s/^>//;
    my @a = split(/-/, $s);
    pop(@a);
    my $array = pop(@a);
    pop(@a);
    $s = join("-", @a);
    return($s,$array);
}

sub bin2dec {
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

exit 0;
