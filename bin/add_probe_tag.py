#!/usr/bin/python

# coding: utf-8

import pysam
import sys

##############################################
def AddProbeTag(bam_path, name, tag, suffix):#
##############################################

	#bam_path = "results/10um_RNase1/05_align_probe/10um_RNase1.align.bam"
	#name = "tmp/sample1"
	#suffix = "probe_tag"
	#tag = "PB"
		
	in_bam = pysam.AlignmentFile(bam_path, "rb")
	out_bam = pysam.AlignmentFile(f"{name}.{suffix}.bam", "wb", template=in_bam)
	counter = 0
	
	print("BAM iteration", file=sys.stderr)
	for record in in_bam.fetch(until_eof=True):
		if record.reference_name:
			record.tags += [(tag, record.reference_name)]
			out_bam.write(record)
		counter = counter + 1
		if counter % 1000000 == 0:
			print(counter, file=sys.stderr)
	
	in_bam.close()
	out_bam.close()
	############################################################################

##########################
if __name__ == "__main__":
	path = sys.argv[1]
	name = sys.argv[2]
	tag = sys.argv[3]
	suffix = sys.argv[4]
	AddProbeTag(path, name, tag, suffix)

