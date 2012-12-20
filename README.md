CASC: A CRISPR Detection Program
================================

Welcome to CASC, an all-in-one CRISPR detection and validation
program designed for use on metagenomic or genomic reads or contigs.

This document contains the information needed to download, install,
and start using CASC.

[1] Downloading CASC
--------------------

### NOTE: CASC was written on Mac OS, and therefore will only work on UNIX-based operating systems (e.g. Mac OS, Linux). Future versions will be Windows friendly (hopefully).

To download, simply pull the CASC repository from GitHub. If you do not know how to do this see https://help.github.com/articles/using-pull-requests

[2] Installing CASC and its Dependencies
----------------------------------------

Once you have downloaded the repository you should see two files and two directories:

  * `casc.pl` the executable Perl script.

  * `README.md` the readme that you're reading now

  * `/BlastDBs` contains two BLAST databases which are used to validate CRISPR calls
  
  * `/bin` contains two programs: a report generator (written in Perl) and a modified version of CRT (written in Java)

### CASC HAS ONLY ONE DEPENDENCY, and it's BLAST. You will need to have a local copy of BLAST installed on your machine, and have you PATH pointing to it. ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/

Assuming you have Perl installed on your machine (and BLAST) you need only to execute the following command to display CASC's help / usage:

    perl casc.pl --help

[3] Using CASC to Find CRISPRs
------------------------------

Say you have a recently sequenced genome, or well assembled metagenomic reads saved in a file `TestSeqs.nuc.fasta` and you would like to find CRISPR spacers within this genome or library. You would execute the following:

    perl casc.pl --in /Path/to/TestSeqs.nuc.fasta

CASC does come with two optional arguments, allowing you to explicitly specify where the output files will be saved, as well as how many CPUs you would like to use. By default outputs are saved in your current working directory, and you will only use 1 CPU. In this example we are saving to a new folder on our home directory and using 2 CPUs:

    perl casc.pl --in /Path/to/TestSeqs.nuc.fasta --outdir /home/dnasko/NewOutput/ -ncpus 2