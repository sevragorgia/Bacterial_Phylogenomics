#!/bin/bash

#create an adequate environment for Phyla_AMPHORA
export PATH=$PATH:/home/sergio/Data/Synechococcus_Phylogenomics/Phyla_Amphora/Scripts;
export Phyla_AMPHORA_home=/home/sergio/Data/Synechococcus_Phylogenomics/Phyla_Amphora;

#define the directory with the protein files
PROTEINS="/home/sergio/Data/Synechococcus_Phylogenomics/Amphora_Selected_Protein_Sequences"

cd $PROTEINS
echo "in $PROTEINS"

MarkerAlignTrim.pl -Trim -OutputFormat fasta >Phyla_Amphora_Align.log
#uncomment this line if you want untrimmed alignments
#MarkerAlignTrim.pl -OutputFormat fasta;
