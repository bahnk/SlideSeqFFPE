#!/usr/bin/python

from Bio import Seq, SeqIO, bgzf, pairwise2
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

#########################
def Process(name, path):#
#########################

	#name = "tmp/sample_test"
	#path = "results/Sample_1/03_filter_out_bad_up_primer_sequence/Sample_1.up_primer_pass.fastq.gz"
	
	in_fastq = gzip.open(path, "rt")
	
	fastq_unmatch = gzip.open(f"{name}.probe_extraction.unmatched.fastq.gz", "wt")
	fastq_short = gzip.open(f"{name}.probe_extraction.too_short.fastq.gz", "wt")
	out_fastq = gzip.open(f"{name}.probe_extraction.pass.fastq.gz", "wt")
	
	rec = SeqIO.SeqRecord("dummy")
	
	total = 0
	unmatched_reads = 0
	too_short_reads = 0
	pass_reads = 0
	
	const_five_prime = "CTGACGAGACCTGAAATGATC"
	var_region_len = 20
	probe_len = 25
	min_len = len(const_five_prime) + var_region_len + probe_len
	
	while rec.seq != "":
	
		rec = Parse(in_fastq)
	
		if rec.seq == "":
			break
	
		total += 1
		if total % 100000 == 0:
			print(str(total).zfill(8))
	
		seq = str(rec.seq)
		m_obj = re.search(const_five_prime, seq)
	
		# cannot find perfect match for constant region
		if not m_obj:
			SeqIO.write(rec, fastq_unmatch, "fastq")
			unmatched_reads += 1
			continue
	
		# length of the oligo
		length = len(seq) - m_obj.start() - 1
	
		# too short
		if length < min_len:
			SeqIO.write(rec, fastq_short, "fastq")
			too_short_reads += 1
			continue
	
		# extract probe sequence
		start = m_obj.start() + len(const_five_prime) + var_region_len
		end = start + probe_len
		probe = seq[start:end]
		phred = rec.letter_annotations.get("phred_quality")[start:end]
	
		# write pass reads
		args = {
			"id": rec.id,
			"name": rec.name,
			"seq": Seq.Seq(probe),
			"letter_annotations": {"phred_quality":phred},
			"description": rec.description
		}
		new_rec = SeqIO.SeqRecord(**args)
		SeqIO.write(new_rec, out_fastq, "fastq")
	
		pass_reads += 1
		#########################################################################
	
	in_fastq.close()
	fastq_unmatch.close()
	fastq_short.close()
	out_fastq.close()
	
	# save metrics
	d = {
		"Name": [name] * 4,
		"Process": ["Probe extraction"] * 4,
		"Metric": ["Total", "Unmatched", "Too short", "Pass"],
		"Value": [total, unmatched_reads, too_short_reads, pass_reads],
	}
	df = pd.DataFrame(data=d)
	df.to_csv(f"{name}.probe_extraction.csv", index=False, header=False)
	############################################################################

###############################################################################
if __name__ == "__main__":
	Process(sys.argv[1], sys.argv[2])


