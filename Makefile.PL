require 5.000;
use ExtUtils::MakeMaker;
    
WriteMakefile(
    NAME            => 'CASC',
    VERSION_FROM    => 'lib/CASC/Reporting.pm',
    EXE_FILES       => ['scripts/casc', 'scripts/CRT1.2b.jar', 'scripts/CRT', 'scripts/para_blastn.pl', 'scripts/para_blastx.pl', 'scripts/casc_report_gen.pl', 'scripts/splitFASTA.pl', 'casc_blast_dbs/RepeatDB_07Oct2014.nhr', 'casc_blast_dbs/RepeatDB_07Oct2014.nin', 'casc_blast_dbs/RepeatDB_07Oct2014.nsq', 'casc_blast_dbs/UniRef_Cas_29Sep2015.phr', 'casc_blast_dbs/UniRef_Cas_29Sep2015.pin', 'casc_blast_dbs/UniRef_Cas_29Sep2015.psq']
    );
