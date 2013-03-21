#!/usr/bin/perl
# splitFASTA

# Shawn Polson - 20 Jan 2007; edit: 5 Feb 2007, 1 Mar 2009
# Accepts multi-sequence FASTA file and returns split multi-sequence file chunks of a specified size.
# Args: none (user prompted for input)
# Dependencies: none
# splitFASTA.pl infasta outputDir outputName numberofseqs
use strict;

my ($inputFile, $outPath, $outFile, $suffix, $count);
my $j=0;
my $fileNumber=1;

#File Operations
$inputFile = $ARGV[0];
#&promptUser("Enter fasta file name to be split");
	open (DAT, $inputFile) or die "Error! Cannot open file $inputFile\n";
$outPath = $ARGV[1];
#&promptUser("Enter output directory where smaller chunks will be saved");
	if(! -d "$outPath") { die "Error! Directory $outPath not found\n"; }
$outFile = $ARGV[2];
#&promptUser("Enter common output filename (prefix only)");
$suffix = "fsa";
#&promptUser("Enter common output suffix","seq");

$count = $ARGV[3];
#&promptUser("Enter number of sequences per output file", "50");

#COMMENT PREVIOUS LINE AND UNCOMMENT FOLLOWING 4 LINES TO USE NUMBER OF FILES AS BASELINE
#my $n = &promptUser("Enter number of files to be created", "50");
#my $i = `egrep -c '^>' $inputFile`;
#chomp $i;
#$count = ceil($i/$n);

open (DAT, $inputFile) or die "Cannot open file $inputFile\n";

open (OUT, "> $outPath/$outFile-$fileNumber.$suffix") or die "Error! Cannot create output file: $outPath/$outFile-$fileNumber.txt\n";

while(<DAT>)
{	if ($_ =~ /^>/) #if new sequence increase counter
	{	$j++;
	}
	if ($j > $count) #if time for new output file
	{	close(OUT);
		$fileNumber++;
		open (OUT, "> $outPath/$outFile-$fileNumber.$suffix") or die "Error! Cannot create output file: $outPath/$outFile-$fileNumber.txt\n";
		$j = 1;
	}
	
	#Output line to file
	print OUT $_;
}

close(OUT);
if ($j == 0)
{	my $sys = `rm $outPath/$outFile-$fileNumber.txt`;
	$j = $count;
}

print "File spliting completed.  $fileNumber files created.  Final file contains $j sequences.\n";
exit 0;

sub promptUser 
{	my ($promptString, $defaultValue) = @_;
	if ($defaultValue) 
	{	print $promptString, "[", $defaultValue, "]: ";
	} 
	else 
	{	print $promptString, ": ";
	}
	$| = 1;				  # force a flush after our print
	$_ = <STDIN>;		  # get the input from STDIN (presumably the keyboard)
	chomp;
	if (defined($defaultValue)) 
	{	return $_ ? $_ : $defaultValue;	   # return $_ if it has a value
	}
	else 
	{	return $_;
	}
}
