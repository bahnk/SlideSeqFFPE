#!/usr/bin/python

# coding: utf-8

import pandas as pd
import pysam
import sys

#############################################################
def SubSample(name, tsv_path, bam_path, n_barcodes, suffix):#
#############################################################

	df = pd.read_csv(tsv_path, sep="\t")
	df = df.loc[ df.umi != "T" * len(df.umi.values[0]) ]
	df = df.loc[ df.final_umi != "T" * len(df.final_umi.values[0]) ]
	df["barcode"] = df.read_id.str.replace(".*_([A-Z]+)_[A-Z]+", "\\1")

	n = min( df.barcode.unique().size , n_barcodes )
	
	barcodes = df\
		.barcode\
		.drop_duplicates()\
		.sample(n)\
		.sort_values()\
		.reset_index(drop=True)
	
	df_sub = df.loc[ df.barcode.isin(barcodes) ]
	df_sub.to_csv(f"{name}.{suffix}.tsv", index=False, sep="\t")
	
	read_ids = set(df_sub.read_id.drop_duplicates().to_list())
	
	
	in_bam = pysam.AlignmentFile(bam_path, "rb")
	out_bam = pysam.AlignmentFile(f"{name}.{suffix}.bam", "wb",
		template=in_bam)
	
	counter = 0
	
	print("BAM iteration", file=sys.stderr)
	
	for record in in_bam.fetch(until_eof=True):
		if record.qname in read_ids:
			out_bam.write(record)
		counter = counter + 1
		if counter % 1000000 == 0:
			print(counter, file=sys.stderr)
	
	in_bam.close()
	out_bam.close()
	############################################################################

#name = "10um_bead-prok"
#tsv_path = "results/10um_bead-prok/06_umi_tools_group/10um_bead-prok.umi_tools_group.tsv"
#bam_path = "results/10um_bead-prok/06_umi_tools_group/10um_bead-prok.umi_tools_group.bam"
#n_barcodes = 5000

	
###############################################################################
if __name__ == "__main__":
	SubSample(
		name=sys.argv[1],
		tsv_path=sys.argv[2],
		bam_path=sys.argv[3],
		n_barcodes=int(sys.argv[4]),
		suffix=sys.argv[5]
	)

