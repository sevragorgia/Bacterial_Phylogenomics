#!/bin/bash

#create an adequate environment
export PATH=$PATH:/home/sergio/Data/Synechococcus_Phylogenomics/Phyla_Amphora/Scripts;
export Phyla_AMPHORA_home=/home/sergio/Data/Synechococcus_Phylogenomics/Phyla_Amphora;

#define the directory with the genomes
GENOMES="/home/sergio/Data/Genomic_Datasets/Collospongia_auris/Symbionts"

#-Phylum:0. All (Default)
#1. Alphaproteobacteria
#2. Betaproteobacteria
#3. Gammaproteobacteria
#4. Deltaproteobacteria
#5. Epsilonproteobacteria
#6. Acidobacteria
#7. Actinobacteria
#8. Aquificae
#9. Bacteroidetes
#10. Chlamydiae/Verrucomicrobia
#11. Chlorobi
#12. Chloroflexi
#13. Cyanobacteria
#14. Deinococcus/Thermus
#15. Firmicutes
#16. Fusobacteria
#17. Planctomycetes
#18. Spirochaetes
#19. Tenericutes
#20. Thermotogae

PHYLUM=13

cd $GENOMES;
echo "in $GENOMES";

#for loop to visit all genome folders
for i in `ls`;
do
	if [ -d $i ]
	then
		cd $i;
		echo "in $i";
		GENOME=`echo $i | cut -d . -f 1,2`;
		FAA_FILE=`echo *.faa.gz | cut -d . -f 1,2,3`;
		if [ -e $FAA_FILE.gz ]
		then
			gunzip $FAA_FILE.gz;
			MarkerScanner.pl -Phylum $PHYLUM -Evalue 1e-24 $FAA_FILE;
			gzip $FAA_FILE;
			for j in `ls *.pep`;
			do
				GENE=`echo $j | cut -d . -f 2,3`
				mv $j $GENOME.$GENE
			done
		#use else to capture names of genomes without faa file or with a different name
		fi
		cd ..;
	fi
done

#this line is extracting the proteins to be used for phylogeny.
#perl MarkerScanner.pl -Phylum 13 GCA_000007925.1_ASM792v1_protein.faa

