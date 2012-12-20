#!/usr/bin/perl -w

# MANUAL FOR spacer_stddev.pl

=pod

=head1 NAME

spacer_report_gen.pl -- what it does

=head1 SYNOPSIS

 spacer_report_gen.pl --fasta /path/to/spacers.fasta --repeat /path/to/repeat.list --cas /path/to/cas.list --out /path/to/output/root.name
                     [--help] [--manual]

=head1 DESCRIPTION

Run through a FASTA file of CRISPR spacers called by mCRT and generate
a report of bonafide/non-bonafide spacers based on:
(1) whether the spacer's repeat showed homology to a known repeat (repeat list) or
(2) A Cas protein was found upstream of the CRISPR array.
(3) Next, script will evaluate the averge and standard deviation of all
    spacers in an effort to pull out bonafide spacers which were missed
    by (1) or (2).

Three output files will then be generated:
(1) /path/to/output/input.report.txt
(2) /path/to/output/input.bonafide.spacers.fasta
(3) /path/to/output/input.nonbonafise.spacers.fasta

=head1 OPTIONS

=over 3

=item B<-f, --fasta>=FILENAME

Input file of spacers called from mCRT in FASTA format. (Required)

=item B<-r, --repeat>=FILENAME

Input file of ID's which hit known repeats. (Required)

=item B<-c, --cas>=FILENAME

Input file of ID's which have Cas upstream of CRISPR. (Required) 

=item B<-o, --out>=FILENAME

Directory where output files will be saved. (Required) 

=item B<-h, --help>

Displays the usage message.  (Optional) 

=item B<-m, --manual>

Displays full manual.  (Optional) 

=back

=head1 DEPENDENCIES

Requires the following Perl libraries.

POSIX
Bio::SeqIO
List::Util qw(sum)

=head1 AUTHOR

Written by Daniel Nasko, 
Center for Bioinformatics and Computational Biology, University of Delaware.

=head1 REPORTING BUGS

Report bugs to dnasko@udel.edu

=head1 COPYRIGHT

Copyright 2012 Daniel Nasko.  
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
use List::Util qw(sum);
use POSIX;
use diagnostics;


#ARGUMENTS WITH NO DEFAULT
my($fasta,$repeat,$cas,$spacer,$outfile,$help,$manual);

GetOptions (	
				"f|fasta=s"	=>	\$fasta,
				"o|out=s"	=>	\$outfile,
                                "s|spacer=s"    =>      \$spacer,
                                "r|repeat=s"    =>      \$repeat,
                                "c|cas=s"       =>      \$cas,
				"h|help"	=>	\$help,
				"m|manual"	=>	\$manual);

# VALIDATE ARGS
pod2usage(-verbose => 2)  if ($manual);
pod2usage(-verbose => 1)  if ($help);
pod2usage( -msg  => "ERROR!  Required argument -f and/or -r and/or -c and/or -o not found.\n", -exitval => 2, -verbose => 1)  if (! $fasta || ! $repeat || ! $cas || ! $outfile);

## GLOBAL VARIABLE SETUP
my $total_spacer = 0; my $total_crispr = 0; my $total_cas = 0; my $total_repeat = 0; my $total_statistics = 0;
my (@STATISTICS,%BONAFIDE,%AVG,%STD,@CAS,@REPEAT);
my $library_name = $fasta;$library_name =~s/.*\///;$library_name =~s/\..*//;
my $total_seq = `fgrep -c ">" $fasta`;chomp($total_seq);
my $total_base = `fgrep -v ">" $fasta | wc -m`;
my $base_per_seq = &Round($total_base/$total_seq, 3);
$total_base = $total_base - $total_seq;
my $rpt_outfile = $outfile . ".report";
my $bon_outfile	= $outfile . ".bonafied.spacer.fasta";
my $nb_outfile	= $outfile . ".nonbonafied.spacer.fasta";

open(OUT,">$rpt_outfile") || die "cannot open the outfile";
open(OUT2,">$bon_outfile") || die "cannot open the bon outfile";
open(OUT3,">$nb_outfile") || die "cannot open the nb outfile";

## Run through Cas lookup
if (-e $cas){
	open(IN,"<$cas");# || die "Cannot open the Cas list file $cas\n\n";
	while(<IN>) {
		chomp;
		$total_cas++;
		my @fields = split(/\t/, $_);
		unless (exists $BONAFIDE{$fields[0]}) { $BONAFIDE{$fields[0]} = 1;}
	}
	close(IN);
	open(IN,"<$cas");# || die "Cannot open the Cas list file $cas\n\n";
	@CAS = <IN>;
	close(IN);
}
## Run through Repeat lookup
if (-e $repeat) {
	open(IN,"<$repeat");# || die "Cannot open the repeat lookup file $repeat\n\n";
	@REPEAT = <IN>;
	close(IN);
	open(IN,"<$repeat");# || die "Cannot open the repeat lookup file $repeat\n\n";
	while(<IN>) {
		chomp;
		$total_repeat++;
		my $format = $_;
		$format =~ s/-.*//;
		unless (exists $BONAFIDE{$format}) { $BONAFIDE{$format} = 1;}
	}
	close(IN);
}
## Find the Spacers that have the right sequence statistics

#my ($seqio_obj,$seq_obj,%seq_statistics);
#$seqio_obj = Bio::SeqIO->new(-file => "$spacer", -format => "fasta" ) or die $!;
#while ($seq_obj = $seqio_obj->next_seq){
#    $total_spacer++;
#    my $sequence = $seq_obj->seq;
#    my $seq_length = length($sequence);
#    my $header = $seq_obj->display_id;
#    my $root = $header;
#    $root =~ s/-\d{1,3}$//;
#    push @{$seq_statistics{$root}},  $seq_length;
#}
my %seq_statistics;
my $header = "";
my $seq = "";
my $lc = 0;
open(IN, "<$spacer") || die "\n Cannot open the input spacer fasta file $spacer\n";
while(<IN>) {
	chomp;
	my $line = $_;
	if ($line =~ m/>/) {
		unless ($lc == 0) {
			$total_spacer++;
			my $seq_length = length($seq);
			my $root = $header;
			$root =~ s/>//;
			$root =~ s/-\d{1,3}$//;
			push @{$seq_statistics{$root}},  $seq_length;
		}
		$header = $line;
		$seq = "";
	}
	else {	$seq .= $line;}
	$lc++;
}
my $seq_length = length($seq);
my $root = $header;
$root =~ s/-\d{1,3}$//;
push @{$seq_statistics{$root}},  $seq_length;
close(IN);
my ($k, $v);
while (($k, $v) = each(%seq_statistics)){
    $total_crispr++;
    my $average = sum(@{$v})/@{$v};
    my $sqtotal = 0;
    my $size = 0;
    my $f = $k;$f =~ s/-.*//;
    foreach(@{$v}) {
        $sqtotal += ($average-$_) ** 2;
        $size++;
    }
    my $std = ($sqtotal / $size) ** 0.5;
    $average = Round($average, 3);
    $std = Round($std, 3);
    $AVG{$f} = $average;
    $STD{$f} = $std;
    if ($average > 19 && $std <=2) {
        push (@STATISTICS, $k);
        my $format = $k;
        $format =~ s/-.*//;
        unless (exists $BONAFIDE{$format}) {    $BONAFIDE{$format} = 1;}
    }
}

## Begin printing report...

print OUT "CASC 1.0

LIBRARY: $library_name
Number of Sequences.....................$total_seq
Number of Bases.........................$total_base
Bases per Sequence......................$base_per_seq


CRISPR IDENTIFICATION
Sequences Containing Putative CRISPRs...$total_crispr
Number of Putative Spacers..............$total_spacer


CRISPR VALIDATION
Sequences with Cas protein upstream.....$total_cas out of $total_crispr
";
if (@CAS) {
    foreach my $i (@CAS) {
        my @field = split(/\t/, $i);
        print OUT "\t>$field[0]\t = ", scalar @{$seq_statistics{"$field[0]-spacer-1"}}, " spacers\t\t$field[1]";
    }
}
else {  print OUT "\tNone...\n";}
print OUT "Repeats matching known repeats..........$total_repeat out of $total_crispr
";
if (@REPEAT) {
    foreach my $i (@REPEAT) {
        chomp($i);
        my $format = $i;
        $format =~ s/-.*//;
        print OUT "\t>$format\t = ", scalar @{$seq_statistics{$i}}, " spacers\n";
    }
}
else {  print OUT "\tNone...\n";}
print OUT "Spacers with Proper Statistics..........", scalar @STATISTICS, " out of $total_crispr\n";
if (@STATISTICS) {
    foreach my $i (@STATISTICS) {
        my $format = $i;
        $format =~ s/-.*//;
        print OUT "\t>$format\t = ", scalar @{$seq_statistics{$i}}, " spacers\n";
        
    }
}
else {  print OUT "\tNone...\n";}

print OUT "
Bonafide CRISPRs = ", scalar keys(%BONAFIDE), " out of $total_crispr = ";
my $percent = &Round(scalar keys(%BONAFIDE)/$total_crispr, 4);
$percent = $percent * 100;
print OUT "$percent%\n\n";

## Begin printing of the exhaustive report
print OUT "\nEXHAUSTIVE REPORT ON PUTATIVE CRISPRs\n\nSequence\t\tCRISPR\t\tAverage\t\tStdDev\n";
while (($k, $v) = each(%seq_statistics)){
    my $f = $k;$f =~ s/-.*//;
    print OUT "$f\t\t\t";
    if (exists $BONAFIDE{$f}) { print OUT "YES\t\t$AVG{$f}\t\t$STD{$f}\n";}
    else {  print OUT "no\t\t$AVG{$f}\t\t$STD{$f}\n";}
}

$header = "";
$seq = "";
$lc = 0;
open(IN,"<$spacer");
while(<IN>) {
	chomp;
	my $line = $_;
	if ($line =~ m/>/) {
		unless ($lc == 0) {	
			my $f = $header;
			$f =~ s/-.*//;
			if (exists $BONAFIDE{$f}) {
				print OUT2 ">$header\n$seq\n";
			}
			else {
				print OUT3 ">$header\n$seq\n";
			}
		}
		$header = $line;
		$header =~ s/>//;
	}
	else {
		$seq .= $line;
	}
	$lc++;
}
my $f = $header;
$f =~ s/-.*//;
if (exists $BONAFIDE{$f}) {
	print OUT2 ">$header\n$seq\n";
}
else {
	print OUT3 ">$header\n$seq\n";
}
close(IN);
print OUT qq|
REFERENCES:
Bland C, Ramsey TL, Sabree F, Lowe M, Brown K, Kyrpides NC, Hugenholtz P:
	CRISPR Recognition Tool (CRT): a tool for automatic detection of
	clustered regularly interspaced palindromic repeats. BMC
	Bioinformatics. 2007 Jun 18;8(1):209
The CRISPRdb database and tools to display CRISPRs and to generate
	dictionaries of spacers and repeats. BMC Bioinformatics.
	2007 May 23;8(1):172
Zheng Zhang, Scott Schwartz, Lukas Wagner, and Webb Miller (2000), "A greedy
	algorithm for aligning DNA sequences", J Comput Biol 2000; 7(1-2):203-14.
Suzek,B.E., Huang,H., McGarvey,P., Mazumder,R. and Wu,C.H. (2007) UniRef:
	comprehensive and non-Redundant UniProt reference clusters. Bioinformatics,
	23, 1282Ð1288.
|;

close(OUT);close(OUT2);close(OUT3);

##SUBROUTINES
sub Round
{	my $number = $_[0];
	my $digits = $_[1];
	$number = (floor(((10**$digits) * $number) + 0.5))/10**$digits;
	return $number;
}


exit 0;
