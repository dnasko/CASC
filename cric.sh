#!/bin/bash -x


# Copyright 2012, Dan Nasko
# Last revised 04 Aug 2012
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# DEPENDENCIES
# None

PROGNAME="cric.sh"

USAGE="
CrIC (CrIC Isn't the Crispr recognition tool )

${PROGNAME} [-f /path/to/input.fasta] [arguments]

-f: Path to the fasta file of interest (required)

-h: display help

${PROGNAME} -f /home/dnasko/GOS.contigs.fasta


"

function error_exit
{

#==============================================================
#  Function for exit due to fatal program error
#	Accepts 1 argument:
#		string containing descriptive error message
#==============================================================
   echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
   exit1
}

if [ $# -eq 0 ]; then echo "$VERSION""$USAGE" >&2; exit 2; fi

while getopts ':f:h' OPTION
do
	case $OPTION in
	  f)	fasta=$OPTARG;;
	  h)	echo "$VERSION""$USAGE" >&2; exit 2;;
	esac
done

# Validate input
if [ ! -f $fasta ]; then error_exit "The fasta file ${fasta} not found or -f argument not provided"; fi

# Create display version of variable
fastaClean=`echo ${fasta} | sed 's/^.*\///' | sed 's/\..*//'`

# Stop execution on error code
set -e

# Create the output repositories
mkdir -p ${HOME}/output_repository
mkdir -p ${HOME}/output_repository/mCRT
mkdir -p ${HOME}/output_repository/blastn
mkdir -p ${HOME}/output_repository/blastx
mkdir -p ${HOME}/output_repository/extract_sequence
mkdir -p ${HOME}/output_repository/bonafide_lookup
mkdir -p ${HOME}/output_repository/cric

## Run mCRT to Call Putative CRISPR Spacers
java -jar ${HOME}/package_cric_v1.0/mCRT1.5.jar ${fasta} ${HOME}/output_repository/mCRT/$fastaClean.raw
mv *.repeat.fsa ${HOME}/output_repository/mCRT
mv *.spacer.fsa ${HOME}/output_repository/mCRT
clear
echo "mCRT is COMPLETE";
## Cheack to see that there were spaces found
if [ -s ${HOME}/output_repository/mCRT/$fastaClean.spacer.fsa ]
	then
		echo There were no CRISPR spacers found in this library
fi

## Extract the original sequences of putative spacers
if [ -e ${HOME}/output_repository/extract_sequence/${fastaClean}.fasta ]
	then
		rm ${HOME}/output_repository/extract_sequence/${fastaClean}.fasta
fi
fgrep ">" ${HOME}/output_repository/mCRT/${fastaClean}.spacer.fsa | sed 's/-.*//' | sed 's/>//' | sort -u | while read line; do egrep -A1 "^>$line$|^>$line " ${fasta} >>${HOME}/output_repository/extract_sequence/${fastaClean}.fasta; done;

## Perform a BLASTn of the repeats of putative spacers
clear
echo "Performing a BLASTn of repeats...";
blastn -query ${HOME}/output_repository/mCRT/${fastaClean}.repeat.fsa -db ${HOME}/package_cric_v1.0/CrFinderRepeatDB.fsa -out ${HOME}/output_repository/blastn/${fastaClean}.btab -evalue 1e-4 -word_size 4 -outfmt 6

## Perform a BLASTx of original sequences with putative spacers to find Cas proteins upstream
clear
echo "Performing a BLASTx of Cas...";
blastx -query ${HOME}/output_repository/extract_sequence/${fastaClean}.fasta -db ${HOME}/package_cric_v1.0/UniRef-CrisprAssociated.100.fsa -out ${HOME}/output_repository/blastx/${fastaClean}.btab -evalue 1e-5  -outfmt 6

## Create list of bonafide spacer arrays from the repeat BLAST and Cas BLAST
if [ -e ${HOME}/output_repository/bonafide_lookup/${fastaClean}.repeat.lookup ]
	then
		rm ${HOME}/output_repository/bonafide_lookup/${fastaClean}.repeat.lookup
fi
cut -f1 ${HOME}/output_repository/blastn/${fastaClean}.btab | sed 's/-.$//' | sed 's/-..$//' | sed 's/-...$//' | sed 's/repeat/spacer/' | sort -u >>${HOME}/output_repository/bonafide_lookup/${fastaClean}.repeat.lookup

if [ -e ${HOME}/output_repository/bonafide_lookup/${fastaClean}.cas.lookup ]
	then
		rm ${HOME}/output_repository/bonafide_lookup/${fastaClean}.cas.lookup
fi
cut -f1 ${HOME}/output_repository/blastx/${fastaClean}.btab | sort -u | while read line; do fgrep -m1 $line ${HOME}/output_repository/blastx/${fastaClean}.btab | cut -f1,2 >> ${HOME}/output_repository/bonafide_lookup/${fastaClean}.cas.lookup; done;

## Run the report generator

perl ${HOME}/package_cric_v1.0/spacer_report_gen.pl -f ${fasta} -r ${HOME}/output_repository/bonafide_lookup/${fastaClean}.repeat.lookup -c ${HOME}/output_repository/bonafide_lookup/${fastaClean}.cas.lookup -s ${HOME}/output_repository/mCRT/${fastaClean}.spacer.fsa -o ${HOME}/output_repository/cric/${fastaClean}

clear
echo "COMPLETE!";
