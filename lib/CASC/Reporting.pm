package CASC::Reporting;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(progress_bar death no_bonafide complete);
%EXPORT_TAGS = ( DEFAULT => [qw(&progress_bar)],
                 Both    => [qw(&progress_bar &death &no_bonafide &complete)]);

sub progress_bar
{
    my ( $got, $total, $width, $char, $silent ) = @_;
    $width ||= 25;
    $char  ||= '=';
    my $num_width = length $total;
    local $| = 1;
    unless ($silent) {
	printf "|%-${width}s| (%.2f%%)\r", 
              $char x (($width-1)*$got/$total). '>', $got, $total, 100*$got/
	      +$total;
    }
}

sub death
{
    my $outdir = $_[0];
    my $infile = $_[1];
    my $death = q{

 . . .-.   .-. .-. .-. .-. .-. .-. .-. 
 |\| | |   |   |(   |  `-. |-' |(  `-. 
 ' ` `-'   `-' ' ' `-' `-' '   ' ' `-' 
                                                                                                                              
};
    $death .= " There were no putative spacers found in $infile\n Outputs have been written to $outdir";

}
sub no_bonafide
{
    my $outdir = $_[0];
    my $infile = $_[1];
    my $no_bonafide = q{
. . .-.   .-. .-. . . .-.   .-. .-. .-. .-.   .-. .-. .-. .-. .-. .-. .-. 
|\| | |   |(  | | |\| |-|   |-   |  |  )|-    `-. |-' |-| |   |-  |(  `-. 
' ` `-'   `-' `-' ' ` ` '   '   `-' `-' `-'   `-' '   ` ' `-' `-' ' ' `-'

};
$no_bonafide .= " There were no bona fide putative spacers found in $infile\n Outputs have been written to $outdir\n\n";
}
sub complete
{
    my $outdir = $_[0];
    my $successful_complete = q{
   ___ ___ ___ ___ ___ ___       ___                 _ 
  / __| _ \_ _/ __| _ \ _ \ ___ | __|__ _  _ _ _  __| |
 | (__|   /| |\__ \  _/   /(_-< | _/ _ \ || | ' \/ _` |
  \___|_|_\___|___/_| |_|_\/__/ |_|\___/\_,_|_||_\__,_|
 

 Final output files saved to:};

    $successful_complete .= " $outdir\n\n";
    print $successful_complete;
}

1;
