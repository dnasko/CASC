![alt text](https://github.com/dnasko/CASC/blob/master/images/casc_logo.png?raw=true "CASC")

Welcome to CASC, an all-in-one CRISPR detection and validation
tool designed for CRISPR discovery in metagenomic or genomic reads or contigs.

CASC, short for "CASC Ain't Simply CRT", is a tool which utilizes
a modified version of the CRISPR Recognition Tool (CRT) to call putative
CRISPR spacers. CASC then validates these spacers by searching against
a database of Cas proteins and CRISPR repeats to get rid of false-positives.

If your input FASTA file contains at least one CRISPR spacer, CASC will
output seven files:

  - **casc.log**: A log with info about your last casc run
  - **file.bonafide.spacers.fasta**: FASTA file containing 'bona fide' or 'valid' CRISPR spacers
  - **file.non-bonafide.spacers.fasta**: FASTA file containing 'non-bona fide' or 'non-valid' CRISPR spacers (i.e. those appearing to be false-positive from CRT)
  - **file.bonafide.repeats.fasta**: FASTA file containing 'bona fide' or 'valid' CRISPR repeats
  - **file.non-bonafide.repeats.fasta**: FASTA file containing 'non-bona fide' or 'non-valid' CRISPR repeats
  - **file.report.md**: Markdown file with some summary statistics on your run
  - **file.results.txt**: Tab-delimmited breakdown of results

1. Downloading CASC
--------------------

### NOTE: CASC was written on Mac OS, and therefore will only work on UNIX-based operating systems (e.g. Mac OS, Linux).

To download, simply clone the CASC repository from GitHub. From the commandline type:

`$ git clone git@github.com:dnasko/CASC.git`

And CASC will be cloned to your working directory.

2. Installing CASC and its Dependencies
----------------------------------------

#### Installing CASC system-wide

If you have sudo acces you can install CASC easily:

```bash
perl Makefile.PL
make
make test
sudo make install
```

#### Installing CASC locally

If you would like to install CASC without sudo:

```bash
perl Makefile.PL PREFIX=/Path/to/where/to/install
make
make test
make install
```

By installing this way you will need to update your
PATH and @INC. This is done by adding the following to your
~/.profile or ~/.bash_profile:

```bash
PATH=$PATH:/Path/to/where/to/install/bin
export PATH
export PERL5LIB=/Path/to/where/to/install/lib/perl5/site_perl
```
Of course, you need to replace "/Path/to/where/to/install" with
where you actually installed it ;)


### CASC HAS ONLY ONE EXTERNAL DEPENDENCY, and it's BLAST. You will need to have a local copy of BLAST installed on your machine, and have its location in your PATH. ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/

Assuming you have Perl installed on your machine (and BLAST) you need only
to execute the following command to display CASC's help / usage:

    casc --help

3. Using CASC to Find CRISPRs
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

4. Version History
-------------------

CASC is routinely updated in an effort to assure that you are validating CRISPRs
with the most up-to-date versions of UniRef and CRISPR DB:

	 Beginning work on verion 2.6 (09Feb2017)
	 Version 2.5 (29Sep2015) == [UniRef 29Sep2015] added, unable to update repeat DB, various bug fixes
     Version 2.4 (07Oct2014) -- [Repeat DB 07Oct2014, now includes predicted DR's] [UniRef 07Oct2014] added -silent argument
     Version 2.3 (17Feb2014) -- [CRISPR DB 17Feb2014] [UniRef 17Feb2014] added -v argument
     Version 2.2 (02Jun2013) -- Improved report formatting and added array coordinates to each array
     Version 2.1 (09Apr2013) -- Various bug fixs, improved report format
     Version 2.0 (22Mar2013) -- Improved multithreading function
     Version 1.2 (17Mar2013) -- Linux compatibility improved, conservative option added
     Version 1.1 (16Mar2013) -- [CRISPR DB 29Jan2013] [UniRef 16 Mar 2013]
     Version 1.0 (19Dec2012) -- Initial Version

5. Credits
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

Enjoy!
