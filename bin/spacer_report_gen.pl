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
my $total_spacer = 0;	## Total number of spacers
my $total_crispr = 0;	## Total number of sequences containing crisprs
my $total_arrays = 0;	## Total number of arrays
my $total_cas = 0;	## Total number of arrays with Cas proteins
my $total_repeat = 0;	## Total number of arrays with known repeats
my $total_statistics = 0;	## Total number of arrays with appropriate spacer statistics
my (@STATISTICS,%BONAFIDE,%AVG,%STD,@CAS,@REPEAT);
my $library_name = $fasta;$library_name =~s/.*\///;$library_name =~s/\..*//;
my $base_per_seq = &Round($total_base/$total_seq, 3);
my $rpt_outfile = $outfile . ".report.txt";
my $bon_outfile	= $outfile . ".bonafide.spacer.fasta";
my $nb_outfile	= $outfile . ".nonbonafide.spacer.fasta";

open(OUT,">$rpt_outfile") || die "cannot open the outfile";
open(OUT2,">$bon_outfile") || die "cannot open the bon outfile";
open(OUT3,">$nb_outfile") || die "cannot open the nb outfile";

## Get Coordinates for each crispr array
my %COORD;
my $raw_spacer_report = $spacer;
$raw_spacer_report =~ s/\.spacer\.fsa$/\.raw/;
my ($strt,$stop,$headerer);
open(IN,"<$raw_spacer_report");
while(<IN>) {
    chomp;
    if ($_ =~ m/SEQUENCE:/) {
        $headerer = $_;
        $headerer =~ s/.*SEQUENCE: *//;
    }
    if ($_ =~ m/Range: /) {
	$strt = $_;
	$strt =~ s/.*Range: //;
	$stop = $strt;
	$strt =~ s/ -.*//;
	$stop =~ s/.* //;
	$COORD{$headerer} = $strt . "," . $stop;
    }
}
close(IN);

############### Run through the Cas lookup file
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
############### Run through Repeat lookup file
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
############### Find the Spacers that have the right sequence statistics

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

############### Formatting spaces needed for formatted report
my $spacing = 15;
if (length($library_name) <= 47) {
    my $dif = 47 - length($library_name);
    for (my $i = 1; $i <= $dif; $i++) {
        $library_name = $library_name . " ";
    }
}
if (length($total_seq) <= $spacing) {
    my $dif = $spacing - length($total_seq);
    for (my $i = 1; $i <= $dif; $i++) {
	$total_seq = $total_seq . " ";
    }
}
if (length($total_base) <= $spacing) {
    my $dif = $spacing - length($total_base);
    for(my $i = 1; $i <= $dif; $i++) {
	$total_base = $total_base . " ";
    }
}
if (length($base_per_seq) <= $spacing) {
    my $dif = $spacing - length($base_per_seq);
    for(my $i = 1; $i <= $dif; $i++) {
	$base_per_seq = $base_per_seq . " ";
    }
}
if (length($total_crispr) <= $spacing) {
    my $dif = $spacing - length($total_crispr);
    for(my $i = 1; $i <= $dif; $i++) {
        $total_crispr = $total_crispr . " ";
    }
}
my $BON = 0;
foreach my $i (keys %BONAFIDE) { $BON++;}
my $PER = Round($BON/$total_arrays, 4);
$PER *= 100;
$PER .= "%";
if (length($BON) <= $spacing) {
    my $dif = $spacing - length($BON);
    for(my $i = 1; $i <= $dif; $i++) {
        $BON = $BON . " ";
    }
}
if (length($PER) <= $spacing) {
    my $dif = $spacing - length($PER);
    for(my $i = 1; $i <= $dif; $i++) {
        $PER = $PER . " ";
    }
}
if (length($total_arrays) <= $spacing) {
    my $dif = $spacing - length($total_arrays);
    for(my $i = 1; $i <= $dif; $i++) {
        $total_arrays = $total_arrays . " ";
    }
}
## Begin printing report...

print OUT "CASC Version $version

+----------------------------------------------------------+
| G E N E R A L      I N F O R M A T I O N                 |
+----------------------------------------------------------+
| Library: $library_name |
| Number of Sequences..................... $total_seq |
| Number of Bases......................... $total_base |
| Bases per Sequence...................... $base_per_seq |
+----------------------------------------------------------+

+----------------------------------------------------------+
| C R I S P R      I D E N T I F I C A T I O N             |
+----------------------------------------------------------+
| Number of Putative CRISPR Arrays........ $total_arrays |
| Number of Bona Fide CRISPR Arrays....... $BON |
| Percent Bona Fide....................... $PER |
+----------------------------------------------------------+\n\n";

## Little more formatting . . .
$total_arrays =~ s/ .*//;
my $form_total = length($total_cas) + length($total_arrays) + 8;
if ($form_total <= 18) {
    my $dif = 18 -$form_total;
    for(my $i = 1; $i <= $dif; $i++) {
	$total_arrays = $total_arrays . " ";
    }
}
print OUT "+----------------------------------------------------------+
| C R I S P R      V A L I D A T I O N                     |
+----------------------------------------------------------+
| Arrays with Cas protein upstream..... $total_cas out of $total_arrays |\n";

########## Printing the formatted output for Cas validated crisprs
if (@CAS) {
    my $org_max = 8;
    my $spcr_max = 16;
    my $uni_max = 24;
    my $start_max = 14;
    my $stop_max = 14;
    foreach my $i (@CAS) {
	my @field = split(/\t/, $i);
	my $coord = '';
	if (exists $COORD{$field[0]}) {$coord = $COORD{$field[0]};}
	my @CRD = split(/,/, $coord);
	my $start_coord = $CRD[0];
	my $stop_coord = $CRD[1];
	if (length($start_coord) > $start_max) { $start_max = length($start_coord);}
	if (length($stop_coord) > $stop_max) { $stop_max = length($stop_coord);}
	if (length($field[0]) > $org_max) { $org_max = length($field[0]);}
	my $spacer_string = scalar @{$seq_statistics{"$field[0]-spacer-1"}} . " spacers";
	if (length($spacer_string) > $spcr_max) {$spcr_max = length($spacer_string);}
	if (length($field[1]) > $uni_max) {$uni_max = length($field[1])}
    }
    $spcr_max += 3;
    $uni_max += 3;
    $start_max += 3;
    $stop_max += 3;
    my $format_string = "%" . $org_max . "s%" . $spcr_max . "s%" . $uni_max . "s%" . $start_max . "s%" . $stop_max . "s";
    my $stop_max2 = $stop_max - 1;
    my $format_string2 = "%" . $org_max . "s%" . $spcr_max . "s%" . $uni_max . "s%" . $start_max . "s%" . $stop_max2 . "s";
    my $dash_size = $org_max - 8;
    my $dashes = "+---------";
    my $seqseqname = "| SeqName";
    if ($dash_size != 0) {
	for (my $i=1;$i<=$dash_size;$i++) {
	    $dashes = $dashes . "-";
	    $seqseqname = $seqseqname . " ";
	}
    }
    $dashes = $dashes . "+";
    $seqseqname = $seqseqname . " |";
    printf OUT ("$format_string2", "$dashes", "------------------+", "--------------------------+", "----------------+", "--------------+\n");
    printf OUT ("$format_string2", "$seqseqname", "Spacers in Seq |", "Cas Protein UniRef Hit |", "Array Start |", "Array Stop |\n");
    printf OUT ("$format_string2", "$dashes", "------------------+", "--------------------------+", "----------------+", "--------------+\n");
    foreach my $i (@CAS) {
	chomp($i);
        my @field = split(/\t/, $i);
	my $start_coord = ' ';
	my $stop_coord = ' ';
	if (exists $COORD{$field[0]}) {
	    my $coord = $COORD{$field[0]};
	    my @CRD= split(/,/, $coord);
	    $start_coord= $CRD[0];
	    $stop_coord = $CRD[1];
	}
	my $spacer_string = scalar @{$seq_statistics{"$field[0]-spacer-1"}} . " spacers";
	$stop_coord = $stop_coord . " |\n";
        print OUT "| ";
	printf OUT ("$format_string", $field[0], $spacer_string, $field[1], $start_coord, $stop_coord);
    }
    printf OUT ("$format_string2", "$dashes", "------------------+", "--------------------------+", "----------------+", "--------------+\n");
    print OUT "\n";
}
else {  print OUT "None...\n";}

########## Printing spacer validated by repeat homology
## Little more formatting again . . .
$total_arrays =~ s/ .*//;
$form_total = length($total_repeat) + length($total_arrays) + 8;
if ($form_total <= 18) {
    my $dif = 18 -$form_total;
    for(my $i = 1; $i <= $dif; $i++) {
	$total_arrays = $total_arrays . " ";
    }
}
print OUT "+----------------------------------------------------------+
| Repeats matching known repeats........$total_repeat out of $total_arrays |\n";
if (@REPEAT) {
    my $org_max = 8;
    my $spcr_max = 16;
    my $start_max = 14;
    my $stop_max = 14;
    foreach my $i (@REPEAT) {
        chomp($i);
        my $format = $i;
        $format =~ s/-.*//;
	my $coord = '';
	if (exists $COORD{$format}) {$coord = $COORD{$format};}
	my @CRD = split(/,/, $coord);
	my $start_coord = $CRD[0];
	my $stop_coord = $CRD[1];
	my $spacer_string = scalar @{$seq_statistics{$i}} . " spacers";
	if (length($format) > $org_max) {$org_max = length($format);}
	if (length($spacer_string) > $spcr_max) {$spcr_max = length($spacer_string);}
	if (length($start_coord) > $start_max) { $start_max = length($start_coord);}
	if (length($stop_coord) > $stop_max) { $stop_max = length($stop_coord);}
    }
    $spcr_max += 3;
    $start_max += 3;
    $stop_max += 3;
    my $format_string = "%" . $org_max . "s%" . $spcr_max . "s%" . $start_max . "s%" . $stop_max . "s";
    my $stop_max2 = $stop_max - 1;
    my $format_string2 = "%" . $org_max . "s%" . $spcr_max . "s%" . $start_max . "s%" . $stop_max2 . "s";
    my $dash_size = $org_max - 8;
    my $dashes = "+---------";
    my $seqseqname = "| SeqName";
    if ($dash_size != 0) {
	for (my $i=1;$i<=$dash_size;$i++) {
	    $dashes = $dashes . "-";
	    $seqseqname = $seqseqname . " ";
	}
    }
    $dashes = $dashes . "+";
    $seqseqname = $seqseqname . " |";
    printf OUT ("$format_string2", "$dashes", "------------------+", "----------------+", "--------------+\n");
    printf OUT ("$format_string2", "$seqseqname", "Spacers in Seq |", "Array Start |", "Array Stop |\n");
    printf OUT ("$format_string2", "$dashes", "------------------+", "----------------+", "--------------+\n");
    foreach my $i (@REPEAT) {
        chomp($i);
        my $format = $i;
        $format =~ s/-.*//;
	my $spacer_string = scalar @{$seq_statistics{$i}} . " spacers";
	my $start_coord = ' ';
	my $stop_coord = ' ';
	if (exists $COORD{$format}) {
	    my $coord = $COORD{$format};
	    my @CRD= split(/,/, $coord);
	    $start_coord= $CRD[0];
	    $stop_coord = $CRD[1];
	}
	$stop_coord = $stop_coord . " |\n";
	print OUT "| ";
        printf OUT ("$format_string", $format, $spacer_string, $start_coord, $stop_coord);
    }
    printf OUT ("$format_string2", "$dashes", "------------------+", "----------------+", "--------------+\n");
    print OUT "\n";
}
else {  print OUT "None...\n";}




########## Printing spacer validated by proper statistics
## Little more formatting again . . .
$total_arrays =~ s/ .*//;
$form_total = length(scalar @STATISTICS) + length($total_arrays) + 8;
if ($form_total <= 18) {
    my $dif = 18 -$form_total;
    for(my $i = 1; $i <= $dif; $i++) {
	$total_arrays = $total_arrays . " ";
    }
}
print OUT "+----------------------------------------------------------+
| Spacers with Proper Statistics........", scalar @STATISTICS, " out of $total_arrays |\n";


if (@STATISTICS) {
    my $org_max = 8;
    my $spcr_max = 16;
    my $start_max = 14;
    my $stop_max = 14;
    foreach my $i (@STATISTICS) {
        my $format = $i;
        $format =~ s/-.*//;
	my $coord = '';
	if (exists $COORD{$format}) {$coord = $COORD{$format};}
	my @CRD = split(/,/, $coord);
	my $start_coord = $CRD[0];
	my $stop_coord = $CRD[1];
        my $spacer_string = scalar @{$seq_statistics{$i}} . " spacers";
	if (length($format) > $org_max) {$org_max = length($format);}
	if (length($spacer_string) > $spcr_max) {$spcr_max = length($spacer_string);}
	if (length($start_coord) > $start_max) { $start_max = length($start_coord);}
	if (length($stop_coord) > $stop_max) { $stop_max = length($stop_coord);}
    }
    $spcr_max += 3;
    $start_max += 3;
    $stop_max += 3;
    my $format_string = "%" . $org_max . "s%" . $spcr_max . "s%" . $start_max . "s%" . $stop_max . "s";
    my $stop_max2 = $stop_max - 1;
    my $format_string2 = "%" . $org_max . "s%" . $spcr_max . "s%" . $start_max . "s%" . $stop_max2 . "s";
    my $dash_size = $org_max - 8;
    my $dashes = "+---------";
    my $seqseqname = "| SeqName";
    if ($dash_size != 0) {
	for (my $i=1;$i<=$dash_size;$i++) {
	    $dashes = $dashes . "-";
	    $seqseqname = $seqseqname . " ";
	}
    }
    $dashes = $dashes . "+";
    $seqseqname = $seqseqname . " |";
    printf OUT ("$format_string2", "$dashes", "------------------+", "----------------+", "--------------+\n");
    printf OUT ("$format_string2", "$seqseqname", "Spacers in Seq |", "Array Start |", "Array Stop |\n");
    printf OUT ("$format_string2", "$dashes", "------------------+", "----------------+", "--------------+\n");
    foreach my $i (@STATISTICS) {
        my $format = $i;
        $format =~ s/-.*//;
        my $spacer_string = scalar @{$seq_statistics{$i}} . " spacers";
        my $start_coord = ' ';
	my $stop_coord = ' ';
	if (exists $COORD{$format}) {
	    my $coord = $COORD{$format};
	    my @CRD= split(/,/, $coord);
	    $start_coord= $CRD[0];
	    $stop_coord = $CRD[1];
	}
	$stop_coord = $stop_coord . " |\n";
	print OUT "| ";
        printf OUT ("$format_string", $format, $spacer_string, $start_coord, $stop_coord);
    }
    printf OUT ("$format_string2", "$dashes", "------------------+", "----------------+", "--------------+\n");
    print OUT "\n";
}
else {  print OUT "None...\n";}



########## Wrapping up the report
## Little more formatting again . . .
$total_arrays =~ s/ .*//;
my $bonafide_crispr_array = scalar keys(%BONAFIDE);
my $non_bonafide_crispr_array = $total_arrays - $bonafide_crispr_array;
my $percent = &Round($bonafide_crispr_array/$total_arrays, 4);
$percent *= 100;
$percent = $percent . "%";

if (length($bonafide_crispr_array) <= 18) {
    my $dif = 18 -length($bonafide_crispr_array);
    for(my $i = 1; $i <= $dif; $i++) {
	$bonafide_crispr_array = $bonafide_crispr_array . " ";
    }
}
if (length($non_bonafide_crispr_array) <= 18) {
    my $dif = 18 -length($non_bonafide_crispr_array);
    for(my $i = 1; $i <= $dif; $i++) {
	$non_bonafide_crispr_array = $non_bonafide_crispr_array . " ";
    }
}
if (length($percent) <= 18) {
    my $dif = 18 -length($percent);
    for(my $i = 1; $i <= $dif; $i++) {
	$percent = $percent . " ";
    }
}
print OUT "
+----------------------------------------------------------+
| V A L I D A T I O N        S U M M A R Y                 |
+----------------------------------------------------------+
| Bona Fide CRISPR arrays.............. $bonafide_crispr_array |
| Non-Bona Fide CRISPR arrays.......... $non_bonafide_crispr_array |
| Percent Bona Fide.................... $percent |
+----------------------------------------------------------+\n\n";




########## Begin printing of the exhaustive report
print OUT "
+----------------------------------------------------------+
| E X H A U S T I V E      R E P O R T                     |
+----------------------------------------------------------+\n";

my $ex_org_max = 8;
my $ex_avg_max = 15;
my $ex_stdev_max = 15;
while (($k, $v) = each(%seq_statistics)){
    my $f = $k;$f =~ s/-.*//;
    if (length($f) > $ex_org_max) { $ex_org_max = length($f);}
    if (length($AVG{$f}) > $ex_avg_max) {	$ex_avg_max = length($AVG{$f})}
    if (length($STD{$f}) > $ex_stdev_max) {	$ex_stdev_max = length($STD{$f})}
}
    $ex_avg_max += 3;
    $ex_stdev_max += 3;
    my $format_string = "%" . $ex_org_max . "s%19" . "s%" . $ex_avg_max . "s%" . $ex_stdev_max . "s";
    my $ex_stdev_max2 = $ex_stdev_max;
    my $format_string2 = "%" . $ex_org_max . "s%19" . "s%" . $ex_avg_max . "s%" . $ex_stdev_max2 . "s";
    my $dash_size = $ex_org_max - 8;
    my $dashes = "+---------";
    my $seqseqname = "| SeqName";
    if ($dash_size != 0) {
	for (my $i=1;$i<=$dash_size;$i++) {
	    $dashes = $dashes . "-";
	    $seqseqname = $seqseqname . " ";
	}
    }
    $dashes = $dashes . "+";
    $seqseqname = $seqseqname . " |";
    printf OUT ("$format_string2", "$dashes", "------------------+", "-----------------+", "----------------+\n");
    printf OUT ("$format_string2", "$seqseqname", "Valid CRISPR? |", "Mean Spcr Len |", "Spcr Len Std |\n");
    printf OUT ("$format_string2", "$dashes", "------------------+", "-----------------+", "----------------+\n");
    

while (($k, $v) = each(%seq_statistics)){
    my $f = $k;$f =~ s/-.*//;
    my $stdstd = $STD{$f};
    $stdstd = $stdstd . " |";
    if (exists $BONAFIDE{$f}) {
	print OUT "| ";
	printf OUT ("$format_string\n", $f, "YES", $AVG{$f}, $stdstd);
    }
    else {  print OUT "| ";printf OUT ("$format_string\n", $f, "no", $AVG{$f}, $stdstd);}
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
|                         E N D     O F     R E P O R T                           |
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
        alignment search tool, J. Mol. Biol. 215 (1990) 403-410.
Suzek,B.E., Huang,H., McGarvey,P., Mazumder,R. and Wu,C.H. (2007) UniRef:
	comprehensive and non-Redundant UniProt reference clusters. Bioinformatics,
	23, 1282D1288.
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
