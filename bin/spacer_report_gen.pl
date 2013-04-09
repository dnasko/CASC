#!/usr/bin/perl -w

# MANUAL FOR spacer_report_gen.pl

=pod

=head1 NAME

spacer_report_gen.pl -- what it does

=head1 SYNOPSIS

 spacer_report_gen.pl --fasta /path/to/spacers.fasta --repeat /path/to/repeat.list --cas /path/to/cas.list --out /path/to/output/root.name --setting yes -y 100 -z 10000
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

=item B<-x, --setting>=FILENAME

Be conservative (1) or liberal (0) with spacer calls.

=item B<-y, --seqs>=INT

Number of sequences in the file. (Required)

=item B<-z, --bases>=INT

Number of bases in the file. (Required)

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
my($fasta,$repeat,$cas,$spacer,$outfile,$setting,$total_seq,$total_base,$version,$help,$manual);

GetOptions (	
				"f|fasta=s"	=>	\$fasta,
				"o|out=s"	=>	\$outfile,
                                "s|spacer=s"    =>      \$spacer,
                                "r|repeat=s"    =>      \$repeat,
                                "c|cas=s"       =>      \$cas,
                                "x|setting=s"   =>      \$setting,
				"y|seqs=i"	=>	\$total_seq,
				"z|bases=i"	=>	\$total_base,
				"v|version=s"	=>	\$version,
				"h|help"	=>	\$help,
				"m|manual"	=>	\$manual);

# VALIDATE ARGS
pod2usage(-verbose => 2)  if ($manual);
pod2usage(-verbose => 1)  if ($help);
pod2usage( -msg  => "ERROR!  Required argument -f not found.\n", -exitval => 2, -verbose => 1)  if (! $fasta );
pod2usage( -msg  => "ERROR!  Required argument -s not found.\n", -exitval => 2, -verbose => 1)  if (! $spacer );
pod2usage( -msg  => "ERROR!  Required argument -r not found.\n", -exitval => 2, -verbose => 1)  if (! $repeat );
pod2usage( -msg  => "ERROR!  Required argument -c not found.\n", -exitval => 2, -verbose => 1)  if (! $cas );
pod2usage( -msg  => "ERROR!  Required argument -o not found.\n", -exitval => 2, -verbose => 1)  if (! $outfile );
pod2usage( -msg  => "ERROR!  Required argument -x not found.\n", -exitval => 2, -verbose => 1)  if (! $setting );
pod2usage( -msg  => "ERROR!  Required argument -y not found.\n", -exitval => 2, -verbose => 1)  if (! $total_seq );
pod2usage( -msg  => "ERROR!  Required argument -z not found.\n", -exitval => 2, -verbose => 1)  if (! $total_base );


## GLOBAL VARIABLE SETUP
my $total_spacer = 0; my $total_crispr = 0; my $total_arrays = 0 ;my $total_cas = 0; my $total_repeat = 0; my $total_statistics = 0;
my (@STATISTICS,%BONAFIDE,%AVG,%STD,@CAS,@REPEAT);
my $library_name = $fasta;$library_name =~s/.*\///;$library_name =~s/\..*//;
my $base_per_seq = &Round($total_base/$total_seq, 3);
my $rpt_outfile = $outfile . ".report.txt";
my $bon_outfile	= $outfile . ".bonafide.spacer.fasta";
my $nb_outfile	= $outfile . ".nonbonafide.spacer.fasta";

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

my %seq_statistics;
my %unique_spacer_containing_sequences;
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
			my $bare_root = $root;
			$bare_root =~ s/-spacer-.*//;
			unless (exists $unique_spacer_containing_sequences{$bare_root}) {
				$unique_spacer_containing_sequences{$bare_root} = 1;
				$total_crispr++;
			}
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
$root =~ s/>//;
push @{$seq_statistics{$root}},  $seq_length;
close(IN);
my ($k, $v);
while (($k, $v) = each(%seq_statistics)){
    $total_arrays++;
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
    if ( $average > 19 && $std <=2 && $setting =~ m/no/ ) {
        push (@STATISTICS, $k);
        my $format = $k;
        $format =~ s/-.*//;
        unless (exists $BONAFIDE{$format}) {    $BONAFIDE{$format} = 1;}
    }
    ## New bit of code added for verion 2.1
    if ($std > 5) {
	my $format = $k;
        $format =~ s/-.*//;
	if (exists $BONAFIDE{$format}) {
		delete $BONAFIDE{$format};
	}
    }
}

## Begin printing report...

print OUT "CASC $version

LIBRARY: $library_name
Number of Sequences.....................$total_seq
Number of Bases.........................$total_base
Bases per Sequence......................$base_per_seq


CRISPR IDENTIFICATION
Sequences Containing Putative CRISPRs...$total_crispr
Number of Putative Arrays...............$total_arrays
Number of Putative Spacers..............$total_spacer


CRISPR VALIDATION
Arrays with Cas protein upstream.....$total_cas out of $total_arrays\n";
if (@CAS) {
    my $org_max = 0;
    my $spcr_max = 0;
    my $uni_max = 0;
    foreach my $i (@CAS) {
        my @field = split(/\t/, $i);
        if (length($field[0]) > $org_max) { $org_max = length($field[0]);}
	my $spacer_string = scalar @{$seq_statistics{"$field[0]-spacer-1"}} . " spacers";
	if (length($spacer_string) > $spcr_max) {$spcr_max = length($spacer_string);}
	if (length($field[1]) > $uni_max) {$uni_max = length($field[1])}
    }
    $spcr_max += 5;
    $uni_max += 5;
    my $format_string = "%" . $org_max . "s%" . $spcr_max . "s%" . $uni_max . "s";
    foreach my $i (@CAS) {
        my @field = split(/\t/, $i);
	my $spacer_string = scalar @{$seq_statistics{"$field[0]-spacer-1"}} . " spacers";
        printf OUT ("$format_string", $field[0], $spacer_string, $field[1]);
    }
    print OUT "\n";
}
else {  print OUT "None...\n";}
print OUT "Repeats matching known repeats..........$total_repeat out of $total_arrays\n";
if (@REPEAT) {
    my $org_max = 0;
    my $spcr_max = 0;
    foreach my $i (@REPEAT) {
        chomp($i);
        my $format = $i;
        $format =~ s/-.*//;
	my $spacer_string = scalar @{$seq_statistics{$i}} . " spacers";
	if (length($format) > $org_max) {$org_max = length($format);}
	if (length($spacer_string) > $spcr_max) {$spcr_max = length($spacer_string);}
    }
    $spcr_max += 5;
    my $format_string = "%" . $org_max . "s%" . $spcr_max . "s";
    foreach my $i (@REPEAT) {
        chomp($i);
        my $format = $i;
        $format =~ s/-.*//;
	my $spacer_string = scalar @{$seq_statistics{$i}} . " spacers";
        printf OUT ("$format_string\n", $format, $spacer_string)
    }
    print OUT "\n";
}
else {  print OUT "None...\n";}
print OUT "Spacers with Proper Statistics..........", scalar @STATISTICS, " out of $total_crispr\n";
if (@STATISTICS) {
    my $org_max = 0;
    my $spcr_max = 0;
    foreach my $i (@STATISTICS) {
        my $format = $i;
        $format =~ s/-.*//;
        my $spacer_string = scalar @{$seq_statistics{$i}} . " spacers";
	if (length($format) > $org_max) {$org_max = length($format);}
	if (length($spacer_string) > $spcr_max) {$spcr_max = length($spacer_string);}
    }
    $spcr_max += 5;
    my $format_string = "%" . $org_max . "s%" . $spcr_max . "s";
    foreach my $i (@STATISTICS) {
        my $format = $i;
        $format =~ s/-.*//;
        my $spacer_string = scalar @{$seq_statistics{$i}} . " spacers";
        printf OUT ("$format_string\n", $format, $spacer_string)
    }
    print OUT "\n";
}
else {  print OUT "None...\n";}

print OUT "
Bonafide CRISPRs = ", scalar keys(%BONAFIDE), " out of $total_arrays = ";
my $percent = &Round(scalar keys(%BONAFIDE)/$total_arrays, 4);
$percent *= 100;
print OUT "$percent%\n\n";

## Begin printing of the exhaustive report
my $ex_org_max = 8;
my $ex_avg_max = 7;
my $ex_stdev_max = 6;
while (($k, $v) = each(%seq_statistics)){
    my $f = $k;$f =~ s/-.*//;
    if (length($f) > $ex_org_max) { $ex_org_max = length($f);}
    if (length($AVG{$f}) > $ex_avg_max) {	$ex_avg_max = length($AVG{$f})}
    if (length($STD{$f}) > $ex_stdev_max) {	$ex_stdev_max = length($STD{$f})}
}
$ex_avg_max += 5;
$ex_stdev_max += 5;
my $first_format_string = "%" . $ex_org_max . "s%11" . "s%" . $ex_avg_max . "s%" . $ex_stdev_max . "s";
print OUT "\nEXHAUSTIVE REPORT ON PUTATIVE CRISPRs\n\n";
printf OUT ("$first_format_string\n", "Sequence", "CRISPR", "Average", "StdDev");
printf OUT ("$first_format_string\n", "========", "======", "=======", "======");
while (($k, $v) = each(%seq_statistics)){
    my $f = $k;$f =~ s/-.*//;
    if (exists $BONAFIDE{$f}) {
	printf OUT ("$first_format_string\n", $f, "YES", $AVG{$f}, $STD{$f});
    }
    else {  printf OUT ("$first_format_string\n", $f, "no", $AVG{$f}, $STD{$f});}
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
				$seq = "";
			}
			else {
				print OUT3 ">$header\n$seq\n";
				$seq = "";
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
print OUT qq{
+---------------------------------------------------------------------------------+
|                               END OF REPORT                                     |
+---------------------------------------------------------------------------------+
REFERENCES:
Bland C, Ramsey TL, Sabree F, Lowe M, Brown K, Kyrpides NC, Hugenholtz P:
	CRISPR Recognition Tool (CRT): a tool for automatic detection of
	clustered regularly interspaced palindromic repeats. BMC
	Bioinformatics. 2007 Jun 18;8(1):209
The CRISPRdb database and tools to display CRISPRs and to generate
	dictionaries of spacers and repeats. BMC Bioinformatics.
	2007 May 23;8(1):172
S.F. Altschul, W. Gish, W. Miller, E.W. Myers, D.J. Lipman, Basic local 
        alignment search tool, J. Mol. Biol. 215 (1990) 403–410.
Suzek,B.E., Huang,H., McGarvey,P., Mazumder,R. and Wu,C.H. (2007) UniRef:
	comprehensive and non-Redundant UniProt reference clusters. Bioinformatics,
	23, 1282Ð1288.
};

close(OUT);close(OUT2);close(OUT3);

##SUBROUTINES
sub Round
{	my $number = $_[0];
	my $digits = $_[1];
	$number = (floor(((10**$digits) * $number) + 0.5))/10**$digits;
	return $number;
}


exit 0;
