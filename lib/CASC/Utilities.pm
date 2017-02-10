package CASC::Utilities;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(dateTime count_seqs);
%EXPORT_TAGS = ( DEFAULT => [qw(&dateTime)],
                 Both    => [qw(&dateTime &count_seqs)]);

sub dateTime
{
    my $date = "";
    my %month = (
        0   =>  "Jan", 1   =>  "Feb", 2   =>  "Mar",
        3   =>  "Apr", 4   =>  "May", 5   =>  "Jun",
        6   =>  "Jul", 7   =>  "Aug", 8   =>  "Sep",
        9   =>  "Oct", 10  =>  "Nov", 11  =>  "Dec"
    );
    my @timeDate = localtime(time);
    $timeDate[5] =~ s/^1/20/;
    $date .= $timeDate[5] . "_" . $month{$timeDate[4]} . "_" . $timeDate[3] . "_";
    $date .= $timeDate[2] . $timeDate[1];
    return $date;
}

sub count_seqs
{
    my $s = $_[0];
    my $seqs = 0;
    open(IN,"<$s") || die "\n Cannot open the temporary file: $s\n\n";
    while(<IN>) {
        chomp;
        if ($_ =~ m/^>/) {
            $seqs++;
        }
    }
    close(IN);
    return($seqs);
}

1;
