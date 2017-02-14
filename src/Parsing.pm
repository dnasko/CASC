package CASC::Parsing;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use CASC::Utilities qw(:Both);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(parse_mcrt parse_spacer_stats spacer_order);
%EXPORT_TAGS = ( DEFAULT => [qw(&parse_mcrt)],
                 Both    => [qw(&parse_mcrt &parse_spacer_stats &spacer_order)]);

sub parse_mcrt
{
    my $mcrt = $_[0];
    my %Results; ## $Results{seq}{array#}{'start'} = blah;
    my $h;
    open(IN,"<$mcrt") || die "\n Cannot open the file: $mcrt\n";
    while(<IN>) {
	chomp;
	if ($_ =~ m/SEQUENCE:/) {
	    $h = $_;
	    $h =~ s/.*SEQUENCE:  //;
	}
	elsif ($_ =~ m/^CRISPR/) {
	    my $array_no = $_;
	    $array_no =~ s/CRISPR //;
	    $array_no =~ s/ .*//;
	    my $start = $_;
	    $start =~ s/.*Range: //;
	    $start =~ s/ .*//;
	    my $stop = $_;
	    $stop =~ s/.* - //;
	    $Results{$h}{$array_no}{'start'} = $start;
	    $Results{$h}{$array_no}{'stop'} = $stop;
	}
    }
    close(IN);
    return %Results;
}

sub parse_spacer_stats
{
    my $infile = $_[0];
    my $h;
    my %Hold;
    my %Results;
    open(IN,"<$infile") || die "\n Cannot open the file: $infile\n";
    while(<IN>) {
	chomp;
	if ($_ =~ m/^>/) {
	    $h = $_;
	    $h =~ s/^>//;
	    my @A = split(/-/, $h);
	    pop(@A);
	    $h = join("-", @A);
	    $h =~ s/-spacer-/_/;
	}
	else {
	    if (exists $Hold{$h}) { $Hold{$h} = $Hold{$h} . "," . length($_); }
	    else { $Hold{$h} = length($_); }
	}
    }
    close(IN);
    foreach my $i (keys %Hold) {
	my @A = split(/_/, $i);
	my $array_no = pop(@A);
	my $root = join("_", @A);
	my ($mean,$std,$n) = mean_std($Hold{$i});
	$Results{$root}{$array_no}{'avg'} = Round($mean, 3);
	$Results{$root}{$array_no}{'std'} = Round($std, 3);
	$Results{$root}{$array_no}{'n'} = $n;
    }
    return %Results;
}

sub spacer_order
{
    my $infile = $_[0];
    my $h;
    my %Hold;
    my @Order;
    open(IN,"<$infile") || die "\n Cannot open the file: $infile\n";
    while(<IN>) {
        chomp;
        if ($_ =~ m/^>/) {
            $h = $_;
            $h =~ s/^>//;
            my @A = split(/-/, $h);
            pop(@A);
            $h = join("-", @A);
            $h =~ s/-spacer-/_/;
	    unless (exists $Hold{$h}) {
		$Hold{$h} = 1;
		push(@Order, $h);
	    }
	}
    }
    close(IN);
    return @Order;
}

1;
