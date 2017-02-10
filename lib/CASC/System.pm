package CASC::System;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(version_info blast_check script_check);
%EXPORT_TAGS = ( DEFAULT => [qw(&version_info)],
                 Both    => [qw(&version_info &blast_check &script_check)]);

sub version_info
{
    my $v = $_[0];
    die " CASC Version $v\n";
}

sub blast_check
{
    my $BLASTN = `which blastn`; unless ($BLASTN =~ m/blastn/) { 
	die "\n\n ERROR: External dependency 'blastn' not installed in system PATH\n\n Download here: (ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/)\n\n And make sure your PATH is pointing to blastn\n\n";}
    my $BLASTX = `which blastx`; unless ($BLASTX =~ m/blastx/) {
        die "\n\n ERROR: External dependency 'blastx' not installed in system PATH\n\n Download here: (ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/)\n\n And make sure your PATH is pointing to blastx\n\n";}
}

sub script_check
{
    my $script = $_[0];
    my $SCRIPT = `which $script`; unless ($SCRIPT =~ m/$script/) {
	die "\n\n ERROR: The CASC script $script is not installed in a directory in your PATH. Please make sure your \$PATH points to the directory that all of the CASC scripts are in.\n\n If you installed to the system (via sudo), this should not be a problem.\n\n If you install locally via `perl Makefile.PL PREFIX=/path/to/prefix`, then make sure you have updated your PATH to include the location of the CASC scripts.\n\n Cant find them? Try:\n\n find ./ -name \"$script\" -print\n\n";
				  }
}

1;
