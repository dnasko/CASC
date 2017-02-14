#!/usr/bin/perl -w

# MANUAL FOR para_blastn.pl

=pod

=head1 NAME

para_blastn.pl -- embarasingly parallel BLASTn

=head1 SYNOPSIS

 para_blastn.pl -query /path/to/infile.fasta -db /path/to/db -out /path/to/output.btab -evalue 1e-3 -outfmt 6 -threads 1
                     [--help] [--manual]

=head1 DESCRIPTION

=head1 OPTIONS

=over 3

=item B<-q, --query>=FILENAME

Input query file in FASTA format. (Required) 

=item B<-d, --d>=FILENAME

Input subject DB. (Required)

=item B<-o, --out>=FILENAME

Path to output btab file. (Required)

=item B<-e, --evalue>=INT

E-value. (Default = 10)

=item B<-f, --outfmt>=INT

Output format. (Default = 6)

=item B<-t, --threads>=INT

Number of CPUs to use. (Default = 1)

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

Copyright 2014 Daniel Nasko.  
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
use threads;
use FindBin;
use Cwd 'abs_path';
my $script_working_dir = $FindBin::Bin;

#ARGUMENTS WITH NO DEFAULT
my($query,$db,$out,$help,$manual);
my $threads = 1;
my $evalue = 10;
my $outfmt = 6;
my @THREADS;

GetOptions (	
				"q|query=s"	=>	\$query,
                                "d|db=s"        =>      \$db,
                                "o|out=s"       =>      \$out,
                                "e|evalue=s"    =>      \$evalue,
                                "f|outfmt=s"    =>      \$outfmt,
                                "t|threads=i"   =>      \$threads,
             			"h|help"	=>	\$help,
				"m|manual"	=>	\$manual);

# VALIDATE ARGS
pod2usage(-verbose => 2)  if ($manual);
pod2usage( {-exitval => 0, -verbose => 2, -output => \*STDERR} )  if ($help);
pod2usage( -msg  => "\n\n ERROR!  Required arguments --query not found.\n\n", -exitval => 2, -verbose => 1)  if (! $query );
my $program = "blastn";
my @chars = ("A".."Z", "a".."z");
my $rand_string;
$rand_string .= $chars[rand @chars] for 1..8;
my $tmp_file = "./$program" . "_tmp_" . $rand_string;
my $root = abs_path($0);
$root =~ s/para_blastn.pl//;
$db = $root . $db;

## Check that blastn and makeblastdb are installed on this machine
my $PROG = `which $program`; unless ($PROG =~ m/$program/) { die "\n\n ERROR: External dependency '$program' not installed in system PATH\n\n (ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/)\n\n";}
my $date = `date`;
print STDERR " Using $threads threads\n";
print STDERR " Using this BLAST: $PROG Beginning: $date\n";

## All clear, time to set up some globals
my $seqs = `egrep -c "^>" $query`;
chomp($seqs);

## Create the working directory, then make blastdb and execute blastn
if ($threads == 1) {
    print `$program -query $query -db $db -out $out -outfmt $outfmt -evalue $evalue -num_threads 1`;
}
else {
    print `mkdir -p $tmp_file`;
    print `chmod 700 $tmp_file`;
    my $seqs_per_file = $seqs / $threads;
    if ($seqs_per_file =~ m/\./) {
	$seqs_per_file =~ s/\..*//;
	$seqs_per_file++;
    }
    print `splitFASTA.pl $query $tmp_file split $seqs_per_file`;
    print `mkdir -p $tmp_file/btab_splits`;
    for (my $i=1; $i<=$threads; $i++) {
	my $blast_exe = "$program -query $tmp_file/split-$i.fsa -db $db -out $tmp_file/btab_splits/split.$i.btab -outfmt $outfmt -evalue $evalue -num_threads 1 -max_target_seqs 10000000";
	push (@THREADS, threads->create('task',"$blast_exe"));
    }
    foreach my $thread (@THREADS) {
	$thread->join();
    }
    print `cat $tmp_file/btab_splits/* > $out`;
    print `rm -rf $tmp_file`;
}
$date = `date`;
print STDERR "\n BLAST complete: $date\n";

sub task
{
    system( @_ );
}

exit 0;
