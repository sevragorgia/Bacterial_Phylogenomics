#!/bin/bash

GENOMES_DIR="/Users/sevra/Repos/Alphaproteobacteria_Phylogenomics/Genomes"
ALIGNMENT_DIR="/Users/sevra/Repos/Alphaproteobacteria_Phylogenomics/Alignments"
TAXON_NAME="Alpha"

#In Cyanobacteria
NUMBER_OF_PROTEINS=257

cd $GENOMES_DIR;
echo "In `pwd`";

#for each protein
for PROTEIN in `seq 1 $NUMBER_OF_PROTEINS`;
do
	IS_SINGLE_COPY=true;
	#for all available genomes
	for GENOME in `ls`;
	do
		if [ -e $GENOME/*.$PROTEIN.pep ]
		then
			n=`grep -c ">" $GENOME/*.$PROTEIN.pep`; #count the occurrence of fasta headers
			echo "$GENOME,$PROTEIN,$n" >>Protein.$PROTEIN.copyNumber.csv;
			if [[ $n -gt 1 ]]
			then
					IS_SINGLE_COPY=false;
			fi
		else
			n=0; #count the occurrence of fasta headers
			echo "$GENOME,$PROTEIN,$n" >>Protein.$PROTEIN.copyNumber.csv;
		fi
	done
	if [[ $IS_SINGLE_COPY == true ]] && [[ -e $ALIGNMENT_DIR/$TAXON_NAME.$PROTEIN.aln ]]
	then
		echo "Protein $PROTEIN is single copy";
		cp -v "$ALIGNMENT_DIR/$TAXON_NAME.$PROTEIN.aln" "$ALIGNMENT_DIR/Single_Copy/$TAXON_NAME.$PROTEIN.aln"
	fi
done