#!/bin/bash



ALIGNMENT_DIR="/Users/sevra/Repos/Alphaproteobacteria_Phylogenomics/Amphora_Selected_Protein_Sequences/Single_Copy"

INPUTS=""

for ALIGNMENT in `ls $ALIGNMENT_DIR/*.nexus`;
do
	INPUTS+=" $ALIGNMENT"
done

java -jar /Users/sevra/BioApps/phyutility_2_2_6/phyutility.jar -concat -in $INPUTS -out Alpha_All.nex -aa
