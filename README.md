![alt text](https://github.com/dnasko/CASC/blob/master/images/casc_logo.png?raw=true "CASC")

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

To download, simply clone the CASC repository from GitHub. From the commandline
simply type:

`$ git clone git@github.com:dnasko/CASC.git`

And CASC will be cloned to your working directory.

[2] Installing CASC and its Dependencies
----------------------------------------

Once you have downloaded the repository you should see two files and four directories:

  * `CASC` the executable Perl script.

  * `README.md` the readme that you're reading now

  * `./casc_blast_dbs` contains two BLAST databases which are used to validate CRISPR calls
  
  * `./casc_bin` contains two programs: a report generator (written in Perl) and a modified version of CRT (written in Java)

  * `./examples` contains three example FASTA files to test CASC with

  * `./images` contains the CASC logo

### CASC HAS ONLY ONE DEPENDENCY, and it's BLAST. You will need to have a local copy of BLAST installed on your machine, and have its location in your PATH. ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/

Assuming you have Perl installed on your machine (and BLAST) you need only
to execute the following command to display CASC's help / usage:

    ./CASC --help

[3] Using CASC to Find CRISPRs
------------------------------

Say you have a recently sequenced genome, or well assembled metagenomic reads
saved in a file `TestSeqs.nuc.fasta` and you would like to find CRISPR spacers
within this genome or library. You would execute the following:

    ./CASC --in=example/a_few_crisprs.fasta

CASC does come with three optional arguments, allowing you to explicitly specify
where the output files will be saved, as well as how many CPUs you would like
to use, and whether or not you would like to be conservative or liberal with CRISPR
call. By default outputs are saved in your current working directory, you
will only use 1 CPU, and call CRISPRs liberally. In this example we are saving
to a new folder on our home directory, using 4 CPUs, and calling CRISPRs conservatively:

    ./CASC --in=/Path/to/TestSeqs.nuc.fasta --outdir=/home/dnasko/NewOutput/ --ncpus=4 --conservative

[4] Version History
-------------------

CASC is routinely updated in an effort to assure that you are validating CRISPRs
with the most up-to-date versions of UniRef and CRISPR DB:

	 Beginning work on verion 2.6 (09Feb2018)
	 Version 2.5 (29Sep2015) == [UniRef 29Sep2015] added, unable to update repeat DB, various bug fixes
     Version 2.4 (07Oct2014) -- [Repeat DB 07Oct2014, now includes predicted DR's] [UniRef 07Oct2014] added -silent argument
     Version 2.3 (17Feb2014) -- [CRISPR DB 17Feb2014] [UniRef 17Feb2014] added -v argument
     Version 2.2 (02Jun2013) -- Improved report formatting and added array coordinates to each array
     Version 2.1 (09Apr2013) -- Various bug fixs, improved report format
     Version 2.0 (22Mar2013) -- Improved multithreading function
     Version 1.2 (17Mar2013) -- Linux compatibility improved, conservative option added
     Version 1.1 (16Mar2013) -- [CRISPR DB 29Jan2013] [UniRef 16 Mar 2013]
     Version 1.0 (19Dec2012) -- Initial Version

[5] Citations
-------------

CASC would not be possible without the help of others who have written some
very nice software and performed exceptional research. CASC uses a modified
version of the CRISPR Recognition Tool (CRT). From there, CASC will then
validate these putative spacers by using a BLAST homology search against the
CRISPR Finder Repeat Database. Lastly a final BLASTX is performed against all
UniRef100P clusters which represent CRISPR-associated proteins (Cas). All of
these citations are included below:

  * Bland C, Ramsey TL, Sabree F, Lowe M, Brown K, Kyrpides NC, Hugenholtz P: CRISPR Recognition Tool (CRT): a tool for automatic detection of clustered regularly interspaced palindromic repeats. BMC Bioinformatics. 2007 Jun 18;8(1):209.

  * The CRISPRdb database and tools to display CRISPRs and to generate dictionaries of spacers and repeats. BMC Bioinformatics. 2007 May 23;8(1):172.
  
  * S.F. Altschul, W. Gish, W. Miller, E.W. Myers, D.J. Lipman, Basic local alignment search tool, J. Mol. Biol. 215 (1990) 403–410.
  
  * Suzek,B.E., Huang,H., McGarvey,P., Mazumder,R. and Wu,C.H. (2007) UniRef: comprehensive and non-Redundant UniProt reference clusters. Bioinformatics, 23, 1282Ð1288.

[6] TODO
--------

  * Provide a "bona fide" repeat FASTA file and a "non-bona fide" repeat FASTA file
  * Add an arg. so that the "Report" file is more machine readable, and less human formatted


Enjoy!
