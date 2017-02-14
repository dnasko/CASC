package CASC::Reporting;

use strict;
use Exporter;
use Cwd 'abs_path';
use CASC::Utilities qw(:Both);
use CASC::System qw(:Both);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(report death no_bonafide complete);
%EXPORT_TAGS = ( DEFAULT => [qw(&report)],
                 Both    => [qw(&report &death &no_bonafide &complete)]);

sub report
{
    my $status = $_[0];
    my $outdir = $_[1];
    if ($status eq "start") {
	my $commandline = $_[2];
	my $mode = "Liberal";
	if ($commandline =~ m/--conservative/) { $mode = "Conservative";}
	open(REP, "|-", "tee $outdir/casc.log") || die "\n ERROR: Cannot open the log file: $outdir/casc.log\n";
	my $abs_path = abs_path($outdir);
	print REP "Commandline: $commandline\n\n";
	print REP "Output Directory: $abs_path\n";
	print REP "Mode: $mode\n\n";
	print REP "===== CASC Started. Log can be found here: " . $abs_path . "/casc.log\n\n";
	close(REP);
    }
    elsif ($status eq "split_fasta") {
	open(REP, "|-", "tee -a $outdir/casc.log") || die "\n ERROR: Cannot open the log file: $outdir/casc.log\n";
	print REP "== Spliting the FASTA file ...................... ";
	close(REP);
    }
    elsif ($status eq "mCRT") {
	open(REP, "|-", "tee -a $outdir/casc.log") || die "\n ERROR: Cannot open the log file: $outdir/casc.log\n";
        print REP "== Running mCRT to find putative spacers ........ ";
        close(REP);
    }
    elsif ($status eq "extraction") {
	open(REP, "|-", "tee -a $outdir/casc.log") || die "\n ERROR: Cannot open the log file: $outdir/casc.log\n";
        print REP "== Extracting sequences with putative spacers ... ";
        close(REP);
    }
    elsif ($status eq "blastn") {
        open(REP, "|-", "tee -a $outdir/casc.log") || die "\n ERROR: Cannot open the log file: $outdir/casc.log\n";
        print REP "== Comparing putative repeats against the repeat database ... ";
        close(REP);
    }
    elsif ($status eq "blastx") {
        open(REP, "|-", "tee -a $outdir/casc.log") || die "\n ERROR: Cannot open the log file: $outdir/casc.log\n";
        print REP "== Searching for Cas proteins ... ";
        close(REP);
    }
    elsif ($status eq "reporting") {
        open(REP, "|-", "tee -a $outdir/casc.log") || die "\n ERROR: Cannot open the log file: $outdir/casc.log\n";
        print REP "== Gathering and printing results ... ";
        close(REP);
    }
    elsif ($status eq "done") {
	my $date = dateTime();
	open(REP, "|-", "tee -a $outdir/casc.log") || die "\n ERROR: Cannot open the log file: $outdir/casc.log\n";
	print REP "Done [$date]\n";
        close(REP);
    }
    elsif ($status eq "no_spacers") {
	my $date = dateTime();
        my $abs_path = abs_path($outdir);
	open(REP, "|-", "tee -a $outdir/casc.log") || die "\n ERROR: Cannot open the log file: $outdir/casc.log\n";
        print REP "\n===== CASC Finished!\n\n CASC log can be found here: " . $abs_path . "/casc.log\n\n";
	print REP "\n!==> No putative spacers were found in your input file. Nothing else to do, bailing out. <==!\n\n";
        close(REP);
	exit 0;
    }
    elsif ($status eq "all_done") {
	my $date = dateTime();
        my $abs_path = abs_path($outdir);
	open(REP, "|-", "tee -a $outdir/casc.log") || die "\n ERROR: Cannot open the log file: $outdir/casc.log\n";
	print REP "\n===== CASC Finished!\n\nCASC log can be found here: " . $abs_path . "/casc.log\n\n";
        close(REP);
    }
}

sub death
{
    my $outdir = $_[0];
    my $infile = $_[1];
    my $death = q{

 . . .-.   .-. .-. .-. .-. .-. .-. .-. 
 |\| | |   |   |(   |  `-. |-' |(  `-. 
 ' ` `-'   `-' ' ' `-' `-' '   ' ' `-' 
                                                                                                                              
};
    $death .= " There were no putative spacers found in $infile\n Outputs have been written to $outdir";

}
sub no_bonafide
{
    my $outdir = $_[0];
    my $infile = $_[1];
    my $no_bonafide = q{
. . .-.   .-. .-. . . .-.   .-. .-. .-. .-.   .-. .-. .-. .-. .-. .-. .-. 
|\| | |   |(  | | |\| |-|   |-   |  |  )|-    `-. |-' |-| |   |-  |(  `-. 
' ` `-'   `-' `-' ' ` ` '   '   `-' `-' `-'   `-' '   ` ' `-' `-' ' ' `-'

};
$no_bonafide .= " There were no bona fide putative spacers found in $infile\n Outputs have been written to $outdir\n\n";
}
sub complete
{
    my $outdir = $_[0];
    my $successful_complete = q{
   ___ ___ ___ ___ ___ ___       ___                 _ 
  / __| _ \_ _/ __| _ \ _ \ ___ | __|__ _  _ _ _  __| |
 | (__|   /| |\__ \  _/   /(_-< | _/ _ \ || | ' \/ _` |
  \___|_|_\___|___/_| |_|_\/__/ |_|\___/\_,_|_||_\__,_|
 

 Final output files saved to:};

    $successful_complete .= " $outdir\n\n";
    print $successful_complete;
}

1;
