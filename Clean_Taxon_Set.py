import sys
import glob
import re

from Bio import AlignIO
from Bio.Align import MultipleSeqAlignment
from Bio.Alphabet import IUPAC, Gapped

infile='/home/sergio/Data/Synechococcus_Phylogenomics/Alignments/Geneious/All_Cyanobacteria_Phylogenomics.nexus'

taxon_sequence_threshold = 0.40

in_alignment=AlignIO.read(open(infile), "nexus", alphabet=Gapped(IUPAC.protein))
alignment_length = in_alignment.get_alignment_length();

out_alignment=MultipleSeqAlignment([], alphabet=Gapped(IUPAC.protein))

for seq_record in in_alignment:
	missing_data = float(seq_record.seq.count("-"))/float(alignment_length)
	print seq_record.id + "\t" + str(missing_data)
	if missing_data < taxon_sequence_threshold:
		out_alignment.append(seq_record)


outname=re.search("(/.+)\.nexus$",infile).group(1) + "." + str(taxon_sequence_threshold)

nexfile=open((outname + ".nexus"), "w")
phyfile=open((outname + ".phylip"), "w")

try:
	nexfile.write(out_alignment.format("nexus"))
	phyfile.write(out_alignment.format("phylip"))
except:
	print "Could not write alignment " + infile + " ", sys.exc_info()[0]
			
nexfile.close()
phyfile.close()


