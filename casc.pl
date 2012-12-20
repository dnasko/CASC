#!/usr/bin/perl -w

# MANUAL FOR casc.pl

=pod

=head1 NAME

casc.pl -- CASC Ain't Simply CRT

=head1 SYNOPSIS

 casc.pl --in /path/to/file.fasta --outdir /path/to/output/directory/ --ncpus 1
                     [--help] [--manual]

=head1 DESCRIPTION

Program to help call CRISPR spacers from FASTA files containing metagenomic
or genomic reads or contigs.
 
=head1 OPTIONS

=over 3

=item B<-i, --in>=FILENAME

Input file in FASTA format. (Required)

=item B<-o, --outdir>=FILENAME

Output directory where all output files will be saved. Default will be the working directory. (Optional)

=item B<-n, --ncpus>=FILENAME

Number of CPUs to use. Default = 1 (Optional)

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
use Cwd 'abs_path';

## ARGUMENTS WITH NO DEFAULT
my($infile,$help,$manual);
## ARGUMENTS WITH DEFAULT
my $outdir = "./casc_output/";
my $ncpus = 1;

GetOptions (	
				"i|in=s"	=>	\$infile,
				"o|outdir=s"	=>	\$outdir,
				"n|ncpus=s"	=>	\$ncpus,
				"h|help"	=>	\$help,
				"m|manual"	=>	\$manual);

# VALIDATE ARGS
pod2usage(-verbose => 2)  if ($manual);
pod2usage(-verbose => 1)  if ($help);
pod2usage( -msg  => "ERROR!  Required argument --in not found.\n", -exitval => 2, -verbose => 1)  if (! $infile );

## Check to see if BLAST installed and in the user's PATH
my $BLASTN = `which blastn`; unless ($BLASTN =~ m/blastn/) {	die "\nERROR!\n External dependency 'blastn' (ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/) not installed in system PATH\n";}
my $BLASTX = `which blastx`; unless ($BLASTX =~ m/blastx/) {	die "\nERROR!\n External dependency 'blastx' (ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/) not installed in system PATH\n";}

## What time is it?
my @date = split(/ /, `date`);			# system call to get the date / time
$date[3] =~ s/:/_/g;chomp($date[5]);		# formatting the date / time
my $DATE = $date[5] . "_" . $date[1] . "_" . $date[2] . "_" . $date[3];

## Format the infile's root
my $infile_root = $infile;
$infile_root =~ s/^.*\///;
$infile_root =~ s/\..*//;

## Format script's working directory
my $script_working_dir = abs_path($0);
$script_working_dir =~ s/casc.pl//;

## If user did not specify an output directory
if ($outdir =~ "./casc_output/") {
    $outdir = "./casc_output/$infile_root-$DATE/";
}

## Create the output directories
print `mkdir -p $outdir`;
print `mkdir -p $outdir/component_processes/blastn`;
print `mkdir -p $outdir/component_processes/blastx`;
print `mkdir -p $outdir/component_processes/bonafide_lookup`;
print `mkdir -p $outdir/component_processes/extract_sequence`;
print `mkdir -p $outdir/component_processes/mCRT`;

## Run mCRT to Call Putative CRISPR Spacers
print "\n [1/6] Calling Putative CRISPR Spacers Using mCRT . . . . . . . . . . . . ";
print `java -jar $script_working_dir/bin/mCRT1.5.jar $infile $outdir/component_processes/mCRT/$infile_root.raw >$outdir/component_processes/mCRT/$infile_root.stdout`;
print `mv *.repeat.fsa $outdir/component_processes/mCRT`;
print `mv *.spacer.fsa $outdir/component_processes/mCRT`;
my $putative_spacers = `fgrep -c ">" $outdir/component_processes/mCRT/$infile_root.spacer.fsa`; chomp($putative_spacers);
if ($putative_spacers == 0) {	die "\n\n There were no putative spacers found in $infile\n\n";}
else {	print "COMPLETE ($putative_spacers putative spacers found)\n";}

## Extract the original sequences of putative spacers
print " [2/6] Extracting spacer sequences from original FASTA file . . . . . . . ";
my %SPACER_ID;
open(IN,"<$outdir/component_processes/mCRT/$infile_root.spacer.fsa") || die "\n Cannot open the spacer file $outdir/component_processes/mCRT/$infile_root.spacer.fsa\n\n";
while(<IN>) {
    chomp;
    my $line = $_;
    if ($line =~ m/>/) {
	$line =~ s/-spacer-.*//;
	$line =~ s/>//;
	$SPACER_ID{$line} = 1;
    }
}
close(IN);
open(OUT,">$outdir/component_processes/extract_sequence/$infile_root.fasta") || die "\n\n Cannot open the output fiel for sequence extraction process: $outdir/component_processes/extract_sequence/$infile_root.fasta\n\n";
open(IN,"<$infile") || die "\n\n Cannot open the original FASTA file $infile\n\n";
my $print_flag = 0;
while(<IN>) {
    chomp;
    my $line = $_;
    if ($line =~ m/>/) {
	$line =~ s/>//;
	$line =~ s/ .*//;
	if (exists $SPACER_ID{$line}) {
	    print OUT ">$line\n";
	    $print_flag =1 ;
	}
	else {	$print_flag = 0;}
    }
    elsif ($print_flag == 1) {
	print OUT $line, "\n";
    }
}
close(IN);
close(OUT);
print "COMPLETE\n";

## Perform a BLASTn of the repeats of putative spacers
print " [3/6] Performing a BLASTN of repeats against putative spacers  . . . . . ";
my $blastn_string = "blastn -query $outdir/component_processes/mCRT/$infile_root.repeat.fsa ";
$blastn_string .= "-db $script_working_dir/BlastDBs/CrFinderRepeatDB.fsa ";
$blastn_string .= "-out $outdir/component_processes/blastn/$infile_root.btab ";
$blastn_string .= "-evalue 1e-4 ";
$blastn_string .= "-word_size 4 ";
$blastn_string .= "-outfmt 6 ";
$blastn_string .= "-num_threads $ncpus ";

print `$blastn_string`;
print "COMPLETE\n";

## Perform a BLASTx of original sequences with putative spacers to find Cas proteins upstream
print " [4/6] Performing a BLASTX of original sequences against Cas proteins . . ";
my $blastx_string = "blastx -query $outdir/component_processes/extract_sequence/$infile_root.fasta ";
$blastx_string .= "-db $script_working_dir/BlastDBs/UniRef-CrisprAssociated.100.fsa ";
$blastx_string .= "-out $outdir/component_processes/blastx/$infile_root.btab ";
$blastx_string .= "-evalue 1e-5 ";
$blastx_string .= "-outfmt 6 ";
$blastx_string .= "-num_threads $ncpus ";
print `$blastx_string`;
print "COMPLETE\n";

## Create list of bonafide spacer arrays from the repeat BLAST and Cas BLAST
print " [5/6] Creating a list of bonafide spacers  . . . . . . . . . . . . . . . ";
open(OUT,">$outdir/component_processes/bonafide_lookup/$infile_root.repeat.lookup");
open(IN,"<$outdir/component_processes/blastn/$infile_root.btab") || die "\n Cannot open the result file for the spacer BLASTn: $outdir/component_processes/blastn/$infile_root.btab\n";
my %REPEAT_ID;
while(<IN>) {
    chomp;
    my @fields = (split/\t/, $_);
    $fields[0] =~ s/-\d{1,3}$//;
    $fields[0] =~ s/repeat/spacer/;
    unless (exists $REPEAT_ID{$fields[0]}) {
	print OUT $fields[0], "\n";
    }
    $REPEAT_ID{$fields[0]} = 1;
}
close(IN);
close(OUT);

open(OUT, ">$outdir/component_processes/bonafide_lookup/$infile_root.cas.lookup") || die "Cannot write to $outdir/component_processes/bonafide_lookup/$infile_root.cas.lookup\n";
open(IN, "<$outdir/component_processes/blastx/$infile_root.btab") || die "\n Cannot open the result file for the Cas BLASTx: $outdir/component_processes/bonafide_lookup/$infile_root.cas.lookup\n";
my %BLASTX_RESULTS;
while(<IN>) {
    chomp;
    my @fields = split(/\t/, $_);
    unless (exists $BLASTX_RESULTS{$fields[0]}) {
	print OUT $fields[0], "\t", $fields[1], "\n";
	$BLASTX_RESULTS{$fields[0]} = $fields[1];
    }
}
close(IN);
close(OUT);
print "COMPLETE\n";

## Run the report generator
print " [6/6] Generating the final report  . . . . . . . . . . . . . . . . . . . ";
my $report_string = "perl $script_working_dir/bin/spacer_report_gen.pl ";
$report_string .= "-f $infile ";
$report_string .= "-r $outdir/component_processes/bonafide_lookup/$infile_root.repeat.lookup ";
$report_string .= "-c $outdir/component_processes/bonafide_lookup/$infile_root.cas.lookup ";
$report_string .= "-s $outdir/component_processes/mCRT/$infile_root.spacer.fsa ";
$report_string .= "-o $outdir/$infile_root";
print `$report_string`;
print "COMPLETE\n\n";

print "\n\n Final output files saved to: $outdir\n\n";












