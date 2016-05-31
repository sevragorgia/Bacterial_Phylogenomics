import sys
import glob
import re

from Bio import AlignIO
from Bio.Alphabet import IUPAC, Gapped

alignmentFiles=glob.glob('/home/sergio/Data/Synechococcus_Phylogenomics/Amphora_Selected_Protein_Sequences/Single_Copy/*.aln')

for file in alignmentFiles:
	alignment=AlignIO.read(open(file), "fasta", alphabet=Gapped(IUPAC.protein))

        print "Processing " + file + "\n"

	for sequence in alignment:
		#extract species name (in Brackets) and use it as species ID
		firstMatch=re.search("\[(.+)\]$", sequence.description).group(1)

		#sometimes there are bracket in the protein name and the first match is a hybrid of
		#protein annotation and species annotation. Then look for a second bracket opening
		#which should be followed by the species name.
		if re.search("\[", firstMatch):
			secondMatch=re.search("\[(.+)$", firstMatch).group(1)
			#substitute other non-valid characters from string
			secondMatch = re.sub(r"[^A-Za-z0-9.]", r"_", secondMatch)
			sequence.id=secondMatch			
		else:
			#substitute other non-valid characters from string
			firstMatch = re.sub(r"[^A-Za-z0-9.]", r"_", firstMatch)
			sequence.id=firstMatch

	outname=re.search("(/.+)\.aln$",file).group(1) + ".nexus"
	out=open(outname, "w")

	try:
		out.write(alignment.format("nexus"))
	except:
		print "Could not write alignment " + file + " ", sys.exc_info()[0]
			
	out.close()

