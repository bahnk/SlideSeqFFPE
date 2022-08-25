#!/usr/bin/python

# coding: utf-8

from Bio import SeqIO
import pandas as pd
import sys

files = [
	"/camp/stp/babs/working/bahn/projects/rodriquess/sam.rodriques/032_spatial_transcriptomics/sequencing/220624_MN01566_0039_A000H3NHJ7/work/93/d770026af101ea50177772c87d63c7/10um_RNase1.count.tsv",
	"/camp/stp/babs/working/bahn/projects/rodriquess/sam.rodriques/032_spatial_transcriptomics/sequencing/220624_MN01566_0039_A000H3NHJ7/work/c0/4947671a5e700e539fd6135b6b4472/5um_RNase2.count.tsv",
	"/camp/stp/babs/working/bahn/projects/rodriquess/sam.rodriques/032_spatial_transcriptomics/sequencing/220624_MN01566_0039_A000H3NHJ7/probes.fasta"
	]

counts_path = files[:-1]
fasta_path = files[-1]

probes = []
for record in SeqIO.parse(fasta_path, "fasta"):
	probes.append(record.id)
probes = sorted(probes)

dfs = [ pd.read_csv(path, sep="\t") for path in counts_path ]


###########################################################################
#def AddProbeTag(bam_path, name, probe_tag, barcode_tag, umi_tag, suffix):#
###########################################################################
#
#	#bam_path = "results/10um_RNase1/05_align_probe/10um_RNase1.align.bam"
#	#name = "tmp/sample1"
#	#suffix = "probe_tag"
#	#tag = "PB"
#		
#	in_bam = pysam.AlignmentFile(bam_path, "rb")
#	out_bam = pysam.AlignmentFile(f"{name}.{suffix}.bam", "wb", template=in_bam)
#	counter = 0
#	
#	print("BAM iteration", file=sys.stderr)
#	for record in in_bam.fetch(until_eof=True):
#		if record.reference_name:
#			record.tags += [(probe_tag, record.reference_name)]
#			record.tags += [(barcode_tag, record.query_name.split("_")[1])]
#			record.tags += [(umi_tag, record.query_name.split("_")[2])]
#			out_bam.write(record)
#		counter = counter + 1
#		if counter % 1000000 == 0:
#			print(counter, file=sys.stderr)
#	
#	in_bam.close()
#	out_bam.close()
#	############################################################################
#
###########################
#if __name__ == "__main__":
#	path = sys.argv[1]
#	name = sys.argv[2]
#	probe_tag = sys.argv[3]
#	barcode_tag = sys.argv[4]
#	umi_tag = sys.argv[5]
#	suffix = sys.argv[6]
#	AddProbeTag(path, name, probe_tag, barcode_tag, umi_tag, suffix)


