#!/bin/bash

#bash script to concatenate the AA sequences of all cyanobacterial genomes in one fasta file

GENOME_DIR="/home/sergio/Data/Genomic_Datasets/Collospongia_auris/Symbionts/Synechococcus/Proteins";
OUTDIR="/home/sergio/Data/Genomic_Datasets/Collospongia_auris/Symbionts/Synechococcus/Proteins";

MAX_PROT=612;
PHYLUM="Cyanobacteria";

for i in `seq 1 $MAX_PROT`;
do
	if [ -e $OUTDIR/$PHYLUM.$i.pep ]
	then
		echo "$OUTDIR/$PHYLUM.$i.pep already exists";
	else
		echo "Concatenating protein $i";
		for GENOME in `ls $GENOME_DIR`;
		do
			if [ -e $GENOME_DIR/$GENOME/*.$i.pep ]
			then
				cat $GENOME_DIR/$GENOME/*.$i.pep >>$OUTDIR/$PHYLUM.$i.pep;
			fi
		done;
	fi
done;



