#!/bin/bash

#bash script to concatenate the AA sequences of all genomes in one fasta file

GENOME_DIR="/Users/sevra/Repos/Alphaproteobacteria_Phylogenomics/New_Genomes";
OUTDIR="/Users/sevra/Repos/Alphaproteobacteria_Phylogenomics/Amphora_Selected_Protein_Sequences";

MAX_PROT=257
PHYLUM="Cyanobacteria"

for i in `seq 1 $MAX_PROT`;
do
		echo "Concatenating protein $i"
		NUMBER_OF_GENOMES=0
		NUMBER_OF_MULTICOPY_COPY_PROTS=0
		for GENOME in `ls $GENOME_DIR`;
		do
			NUMBER_OF_GENOMES=$((NUMBER_OF_GENOMES+1))
			if [ -e $GENOME_DIR/$GENOME/*.$i.pep ]
			then
				COPIES=`grep -c ">" $GENOME_DIR/$GENOME/*.$i.pep`
				#protein is single copy in this genome add to concatenated file
				if [ $COPIES -eq 1 ]
				then
					cat $GENOME_DIR/$GENOME/*.$i.pep >>$OUTDIR/$PHYLUM.$i.pep
				else
					echo "Protein $i in genome $GENOME has $COPIES copies: excluding from analysis"
					NUMBER_OF_MULTICOPY_COPY_PROTS=$((NUMBER_OF_MULTICOPY_COPY_PROTS+1))
				fi
			fi
		done;
		echo "$NUMBER_OF_MULTICOPY_COPY_PROTS/$NUMBER_OF_GENOMES proteins excluded from analysis"
done;



