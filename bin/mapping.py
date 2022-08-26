#!/usr/bin/python

# coding: utf-8

from collections import defaultdict

import pandas as pd
import pysam
import sys

####################################
def count_mappings(bam_path, name):#
####################################

	#bam_path = "results/10um_RNase1/05_align_probe/10um_RNase1.align.bam"
	#name = "tmp/sample1"
	
	bam = pysam.AlignmentFile(bam_path, "rb")
	probes = defaultdict(set)
	counter = 0
	
	print("BAM iteration", file=sys.stderr)
	for record in bam.fetch(until_eof=True):
		probes[record.qname].add(record.reference_name)
		counter = counter + 1
		if counter % 1000000 == 0:
			print(counter, file=sys.stderr)
	
	s = pd.Series(probes)
	
	mappings = (s == {None}).map(lambda x: "Unmapped" if x else "Mapped")\
		.value_counts()\
		.sort_values(ascending=False)\
		.to_frame()\
		.reset_index()\
		.rename(columns={"index": "Metric", 0: "Reads"})\
		.assign(Name=name)\
		.assign(Process="Alignment")\
		.loc[:, ["Name", "Process", "Metric", "Reads"]]
	
	mappings.to_csv(f"{name}.mapped.csv", index=False, header=False)
	
	hits = s\
		.loc[ s != {None} ]\
		.map(len)\
		.value_counts()\
		.sort_values(ascending=False)\
		.to_frame()\
		.reset_index()
	
	hits.to_csv(f"{name}.hits.csv", index=False, header=False)
	############################################################################

##########################
if __name__ == "__main__":
	path = sys.argv[1]
	name = sys.argv[2]
	count_mappings(path, name)

