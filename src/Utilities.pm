package CASC::Utilities;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(dateTime count_seqs split_multifasta get_basename roundup run_mCRT extract_headers extract_seqs btab2lookup mean_std rounddown Round);
%EXPORT_TAGS = ( DEFAULT => [qw(&dateTime)],
                 Both    => [qw(&dateTime &count_seqs &split_multifasta &get_basename &roundup &run_mCRT &extract_headers &extract_seqs &btab2lookup &mean_std &rounddown &Round)]);

sub dateTime
{
    my $date = "";
    my %month = (
        0   =>  "Jan", 1   =>  "Feb", 2   =>  "Mar",
        3   =>  "Apr", 4   =>  "May", 5   =>  "Jun",
        6   =>  "Jul", 7   =>  "Aug", 8   =>  "Sep",
        9   =>  "Oct", 10  =>  "Nov", 11  =>  "Dec"
    );
    my @timeDate = localtime(time);
    $timeDate[5] =~ s/^1/20/;
    $date .= $timeDate[3] . "" . $month{$timeDate[4]} . "" . $timeDate[5] . " ";
    $date .= $timeDate[2] . ":" . $timeDate[1];
    return $date;
}

sub count_seqs
{
    my $s = $_[0];
    my $seqs = 0;
    my $bases = 0;
    open(IN,"<$s") || die "\n Cannot open the temporary file: $s\n\n";
    while(<IN>) {
        chomp;
        if ($_ =~ m/^>/) {  $seqs++;    }
	else {   $bases += length($_);	}
    }
    close(IN);
    return($seqs, $bases);
}

sub split_multifasta
{
    my $nseqs = $_[0];
    my $ncpus = $_[1];
    my $infile = $_[2];
    my $outdir = $_[3];
    my $infile_root = get_basename($infile);
    my $seqs_per_file = roundup($nseqs/$ncpus);
    print `splitFASTA.pl $infile $outdir $infile_root $seqs_per_file`;
    my @Files;
    for (my $i=1;$i<=$ncpus;$i++) {
	my $file_name = $outdir . "/" . $infile_root . "-" . $i . ".fsa";
	push (@Files, $file_name);
    }
    return @Files;
}

sub get_basename
{
    my $s = $_[0];
    $s =~ s/.*\///;
    $s =~ s/\..*//;
    return $s;
}

sub roundup
{
    my $n = shift;
    return(($n == int($n)) ? $n : int($n + 1))
}
sub rounddown
{
    my $n = shift;
    return(int($n));
}
sub Round
{       my $number = $_[0];
        my $digits = $_[1];
        $number = (rounddown(((10**$digits) * $number) + 0.5))/10**$digits;
        return $number;
}

sub run_mCRT
{
    my @Files = @{$_[0]};
    my $outdir = $_[1];
    my $infile_root = $_[2];
    my @THREADS;
    foreach my $file (@Files) {
	my $mod_file = get_basename($file);
	my $job = qq|CRT $file $outdir/component_processes/mCRT/$mod_file.raw|;
	push (@THREADS, threads->create('task',"$job"));
    }
    foreach my $thread (@THREADS) {
	$thread->join();
    }
    if (-e "$outdir/component_processes/mCRT/$infile_root.raw") { print `rm $outdir/component_processes/mCRT/$infile_root.raw`;}
    print `cat $outdir/component_processes/mCRT/*.raw > $outdir/component_processes/mCRT/$infile_root.raw`;
    foreach my $file (@Files) {
	my $mod_file = get_basename($file);
	print `rm $outdir/component_processes/mCRT/$mod_file.raw`;
    }
    print `cat $infile_root-*.repeat.fsa > $outdir/component_processes/mCRT/$infile_root.repeat.fsa`;
    print `cat $infile_root-*.spacer.fsa > $outdir/component_processes/mCRT/$infile_root.spacer.fsa`;
    print `rm $infile_root-*.repeat.fsa`;
    print `rm $infile_root-*.spacer.fsa`;
    my ($putative_spacers,$putative_spacers_bases) = count_seqs("$outdir/component_processes/mCRT/$infile_root.spacer.fsa");
    return $putative_spacers;
}

sub extract_headers
{
    my $file = $_[0];
    my %Hash;
    open(IN,"<$file") || die "\n Cannot open the file: $file\n";
    while(<IN>) {
	chomp;
	if ($_ =~ m/^>/) {
	    my $h = $_;
	    $Hash{clean_header($_)} = 0;
	}
    }
    close(IN);
    return %Hash;
}

sub extract_seqs
{
    my $infile = shift;
    my $outfile = shift;
    my %Hash = @_;
    my $print_flag = 0;
    open(OUT,">$outfile") || die "\nError: Cannot write to outfile: $outfile\n";
    open(IN,"<$infile") || die "\n Cannot read infile: $infile\n";
    while(<IN>) {
	chomp;
	if ($_ =~ m/^>/) {
	    $print_flag = 0;
	    if (exists $Hash{clean_header($_)}) {
		$print_flag = 1;
		print OUT $_ . "\n";
	    }
	}
	elsif ($print_flag == 1) {
	    print OUT $_ . "\n";
	}
    }
    close(IN);
    close(OUT);
    my $expecting = keys %Hash;
    my ($found_seqs,$found_bases) = count_seqs($outfile);
    if ($expecting != $found_seqs) { print "\n!==> Warning, expected to extract $expecting sequences, but only extracted $found_seqs sequences <==!\n"; }
}

sub btab2lookup
{
    my $infile = $_[0];
    my $outfile = $_[1];
    my %SeenBefore;
    open(OUT,">$outfile") || die "\n Cannot write to outfile $outfile\n";
    open(IN,"<$infile") || die "\n Cannot open the file: $infile\n";
    while(<IN>) {
	chomp;
	my @a = split(/\t/, $_);
	if ($a[0] =~ m/-repeat-/) {
	    $a[0] =~ s/-repeat-/-spacer-/;
	    unless (exists $SeenBefore{$a[0]}) {
		print OUT $a[0] . "\n";
	    }
	    $SeenBefore{$a[0]} = 1;
	}
	else {
	    unless (exists $SeenBefore{$a[0]}) {
		print OUT $a[0] . "\t" . $a[1] . "\n";
	    }
	    $SeenBefore{$a[0]} = 1;
	}
    }
    close(IN);
    close(OUT);
}

sub clean_header
{
    my $s = $_[0];
    $s =~ s/^>//;
    $s =~ s/ .*//;
    $s =~ s/-spacer-\d+-\d+//;
    return $s;
}

sub mean_std
{
    my $s = $_[0];
    my @S = split(/,/, $s);
    my $sum = 0;
    foreach my $i (@S) {
        $sum += $i;
    }
    my $mean = $sum / scalar(@S);

    my $sqtotal = 0;
    foreach my $i (@S) {
        $sqtotal += ($mean-$i) ** 2;
    }
    my $std = ($sqtotal / (scalar(@S)-1)) ** 0.5;
    return($mean,$std,scalar(@S));
}

sub task
{
    system( @_ );
}

1;
