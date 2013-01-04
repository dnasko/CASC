CASC: A CRISPR Detection Tool
=============================

Welcome to CASC, an all-in-one CRISPR detection and validation
tool designed for CRISPR discovery in metagenomic or genomic reads or contigs.

CASC, short for "CASC Ain't Simply CRT", is a tool which utilizes
a modified version of the CRISPR Recognition Tool (CRT) to call putative
CRISPR spacers. CASC then goes on to leverage two BLAST databases
to help validate these spacers in an effort to reduce the high
false-positive rate.

If your input FASTA file contains at least one CRISPR spacer, CASC will
output three files:

  * A FASTA file containing 'bona fide' or 'valid' CRISPR Spacers
  
  * A FASTA file containing 'non-bona fide' or 'non-valid' CRISPR Spacers (i.e. those appearing to be false-positive from CRT)
  
  * A summary report

This document contains the information needed to download, install,
and start using CASC.

[1] Downloading CASC
--------------------

### NOTE: CASC was written on Mac OS, and therefore will only work on UNIX-based operating systems (e.g. Mac OS, Linux).
Future versions will be Windows friendly (hopefully).

To download, simply pull the CASC repository from GitHub. If you do not
know how to do this see https://help.github.com/articles/using-pull-requests

[2] Installing CASC and its Dependencies
----------------------------------------

Once you have downloaded the repository you should see two files and two directories:

  * `casc.pl` the executable Perl script.

  * `README.md` the readme that you're reading now

  * `/BlastDBs` contains two BLAST databases which are used to validate CRISPR calls
  
  * `/bin` contains two programs: a report generator (written in Perl) and a modified version of CRT (written in Java)

### CASC HAS ONLY ONE DEPENDENCY, and it's BLAST. You will need to have a local copy of BLAST installed on your machine, and have you PATH pointing to it. ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/

Assuming you have Perl installed on your machine (and BLAST) you need only
to execute the following command to display CASC's help / usage:

    perl casc.pl --help

[3] Using CASC to Find CRISPRs
------------------------------

Say you have a recently sequenced genome, or well assembled metagenomic reads
saved in a file `TestSeqs.nuc.fasta` and you would like to find CRISPR spacers
within this genome or library. You would execute the following:

    perl casc.pl --in /Path/to/TestSeqs.nuc.fasta

CASC does come with two optional arguments, allowing you to explicitly specify
where the output files will be saved, as well as how many CPUs you would like
to use. By default outputs are saved in your current working directory, and you
will only use 1 CPU. In this example we are saving to a new folder on our home
directory and using 2 CPUs:

    perl casc.pl --in /Path/to/TestSeqs.nuc.fasta --outdir /home/dnasko/NewOutput/ -ncpus 2

[4] Citations
-------------

CASC would not be possible without the help of others who have written some
very nice software and performed exceptional research. CASC uses a modified
version of the CRISPR Recognition Tool (CRT). From there, CASC will then
validate these putative spacers by using a BLAST homology search against the
CRISPR Finder Repeat Database. Lastly a final BLASTX is performed against all
UniRef100P clusters which represent CRISPR-associated proteins (Cas). All of
these citations are included below:

  * Bland C, Ramsey TL, Sabree F, Lowe M, Brown K, Kyrpides NC, Hugenholtz P: CRISPR Recognition Tool (CRT): a tool for automatic detection of clustered regularly interspaced palindromic repeats. BMC Bioinformatics. 2007 Jun 18;8(1):209

  * The CRISPRdb database and tools to display CRISPRs and to generate dictionaries of spacers and repeats. BMC Bioinformatics. 2007 May 23;8(1):172
  
  * Zheng Zhang, Scott Schwartz, Lukas Wagner, and Webb Miller (2000), "A greedy algorithm for aligning DNA sequences", J Comput Biol 2000; 7(1-2):203-14.
  
  * Suzek,B.E., Huang,H., McGarvey,P., Mazumder,R. and Wu,C.H. (2007) UniRef: comprehensive and non-Redundant UniProt reference clusters. Bioinformatics, 23, 1282Ð1288.

Enjoy!
