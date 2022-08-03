#!/usr/bin/python

from Bio import SeqIO, bgzf, pairwise2
from collections import defaultdict
from io import StringIO

import gzip
import pandas as pd
import re
import sys

###############################
def HammingDistance(sequence):#
###############################
	up = "TCTTCAGCGTTCCCGAGA"
	d = 0
	for a, b in zip(sequence, up):
		if a != b:
			d = d + 1
	return d
	############################################################################

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
	############################################################################

##############################################
def Process(name, path1, path2, threshold=3):#
##############################################

	#name = "up_primer"
	#path1 = "test1.fastq.gz"
	#path2 = "test2.fastq.gz"
	#threshold = 3
	
	fastq1 = gzip.open(path1, "rt")
	fastq2 = gzip.open(path2, "rt")
	
	fastq_pass = gzip.open(f"{name}.up_primer_pass.fastq.gz", "wt")
	fastq_fail = gzip.open(f"{name}.up_primer_fail.fastq.gz", "wt")
	
	rec1 = SeqIO.SeqRecord("dummy")
	
	counter = 1

	total = 0
	up_pass = 0
	up_fail = 0
	
	while rec1.seq != "":
	
		rec1 = Parse(fastq1)
		rec2 = Parse(fastq2)
	
		if rec1.seq == "" or rec2.seq == "":
			break
	
		distance = HammingDistance(rec1.seq)

		total += 1
	
		if distance <= threshold:
			SeqIO.write(rec2, fastq_pass, "fastq")
			up_pass += 1
		else:
			SeqIO.write(rec2, fastq_fail, "fastq")
			up_fail += 1
	
		counter += 1
		if counter % 100000 == 0:
			print(str(counter).zfill(8))
		#########################################################################

	fastq1.close()
	fastq2.close()
	fastq_pass.close()
	fastq_fail.close()

	# save metrics
	d = {
		"Name": [name] * 3,
		"Process": ["UP primer"] * 3,
		"Metric": ["Total", "Pass", "Fail"],
		"Value": [total, up_pass, up_fail],
	}
	df = pd.DataFrame(data=d)
	df.to_csv(f"{name}.up_primer_metrics.csv", index=False, header=False)
	############################################################################

###############################################################################
if __name__ == "__main__":
	Process(sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]))

