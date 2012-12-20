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

  * `/BlastDBs` contains two BLAST databases which are used to validate CRISPR calls
  
  * `/bin` contains two programs: a report generator (written in Perl) and a modified version of CRT (written in Java)
  
  * `README.md` the readme that you're reading now
  
  * `casc.pl` the executable Perl script.