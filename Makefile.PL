require 5.000;
use ExtUtils::MakeMaker;
    
WriteMakefile(
    NAME            => 'CASC',
    VERSION_FROM    => 'lib/CASC/Reporting.pm',
    EXE_FILES       => ['scripts/casc', 'scripts/CRT1.2b.jar', 'scripts/CRT', 'scripts/para_blastn.pl', 'scripts/para_blastx.pl', 'scripts/spacer_report_gen.pl', 'scripts/splitFASTA.pl']
    );
