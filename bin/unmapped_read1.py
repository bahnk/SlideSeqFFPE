#!/usr/bin/python

from Bio import SeqIO, bgzf, pairwise2
from collections import defaultdict
from io import StringIO

import gzip
import pandas as pd
import re
import sys

###################
def Parse(handle):#
###################

	name = handle.readline()
	seq = handle.readline()
	desc = handle.readline()
	qual = handle.readline()

	if name == "":
		return SeqIO.SeqRecord("")
	else:
		return SeqIO.read(StringIO("\n".join([name, seq, desc, qual])), "fastq")
	###########################################################################

#############################################
def Process(name, path1, path2, reads_path):#
#############################################

	#name = "tmp/FFPE_5um_RNaseH"
	#path1 = "results/demultiplexing/FFPE_5um_RNaseH_S5_L001_R1_001.fastq.gz"
	#path2 = "results/demultiplexing/FFPE_5um_RNaseH_S5_L001_R2_001.fastq.gz"
	#reads_path = "results/FFPE_5um_RNaseH/09_unmapped/FFPE_5um_RNaseH.unmapped.txt"
	
	# unmapped read IDs
	reads = set()
	f = open(reads_path, "r")
	for read_id in f:
		reads.add( read_id.rstrip().split("_")[0] )
	
	fastq1 = gzip.open(path1, "rt")
	fastq2 = gzip.open(path2, "rt")
	
	rec1 = SeqIO.SeqRecord("dummy")
	
	counter = 1
	
	regex = re.compile("TCTTCAGCGTTCCCGAGA")
	
	rows = []
	
	while rec1.seq != "":
	
		rec1 = Parse(fastq1)
		rec2 = Parse(fastq2)
	
		if rec1.id in reads:
	
			rev = rec2.seq.reverse_complement()
			m = regex.search(str(rev))
	
			if m:
	
				# TODO: change this for a proper read structure, but no time
				barcode1 = rec1.seq[0:8] + rec1.seq[26:31]
				barcode2 = rev[m.start()-8:m.start()] + rev[m.end():m.end()+5]
	
				umi1 = rec1.seq[35:42]
				umi2 = rev[m.end()+9:m.end()+16]
	
				d = {
					"Read ID": rec1.id,
					"Same barcode?": barcode1 == barcode2,
					"Same UMI?": umi1 == umi2,
					"Barcode Read 1": barcode1,
					"Barcode Read 2": barcode2,
					"UMI Read 1": umi1,
					"UMI Read 2": umi2,
					"Read 1": rec1.seq,
					"Read 2 reverse complemented": rev
				}
	
	
				rows.append((d))
	
		counter += 1
		if counter % 100000 == 0:
			print(str(counter).zfill(8))
	
	fastq1.close()
	fastq2.close()
	
	# save metrics
	df = pd.DataFrame.from_records(rows)
	df.to_csv(f"{name}.reads.csv", index=False)
	
	# save counts
	counts = df\
		.groupby(["Same barcode?", "Same UMI?"])\
		.apply(lambda x: x.shape[0])\
		.reset_index()\
		.rename(columns={0: "Reads"})
	counts.to_csv(f"{name}.counts.csv", index=False)
	###########################################################################

###############################################################################
if __name__ == "__main__":
	Process(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])

