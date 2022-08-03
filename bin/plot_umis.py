#!/usr/bin/python

# coding: utf-8

from collections import defaultdict

import matplotlib as mpl
import pandas as pd
import pysam
import seaborn as sns
import sys

mpl.use('Agg')
sns.set(rc={'figure.figsize':(8,8)})

################################
def count_umis(bam_path, name):#
################################

	#bam_path = "results/10um_RNase1/05_align_probe/10um_RNase1.align.bam"
	#name = "sample1"
	
	bam = pysam.AlignmentFile(bam_path, "rb")
	counts = defaultdict(set)
	probes = defaultdict(set)
	counter = 0
	mapped = 0
	
	print("BAM iteration", file=sys.stderr)
	for record in bam.fetch(until_eof=True):
		counter = counter + 1
		if counter % 1000000 == 0:
			print(counter, file=sys.stderr)
		if record.reference_name:
			read_id = record.qname.split("_")[0]
			barcode = record.qname.split("_")[1]
			umi = record.qname.split("_")[2]
			counts[(barcode, umi)].add(read_id)
			probes[(barcode, umi)].add(record.reference_name)
	
	############################################################################
	reads = pd\
		.Series(counts)\
		.map(len)\
		.sort_values(ascending=False)\
		.reset_index()\
		.rename(columns={"level_0": "Barcode", "level_1": "UMI", 0: "Reads"})
	
	############################################################################
	hist_reads = sns.histplot(data=reads, x="Reads", log_scale=True)
	hist_reads.set_title(
		"Reads per UMI ({:,} reads, {:,} UMIs)"\
			.format(reads.Reads.sum()), reads.shape[0]
	)
	fig = hist_reads.get_figure()
	fig.savefig(f"{name}.reads_per_umi.pdf")
	fig.savefig(f"{name}.reads_per_umi.png")
	fig.clf()
	
	############################################################################
	umis = reads\
		.loc[:,["Barcode", "UMI"]]\
		.groupby("Barcode")\
		.apply(lambda x: x.shape[0])\
		.sort_values(ascending=False)\
		.reset_index()\
		.rename(columns={"Barcode": "Barcode", 0: "UMIs"})
	
	############################################################################
	hist_umis = sns.histplot(data=umis, x="UMIs", log_scale=True)
	hist_umis.set_title(
		"UMIs per barcode\n({:,} reads, {:,} barcodes, {:,} UMIs)"\
			.format(reads.Reads.sum(), reads.Barcode.unique().size, umis.UMIs.sum())
	)
	fig = hist_umis.get_figure()
	fig.savefig(f"{name}.umis_per_barcode.pdf")
	fig.savefig(f"{name}.umis_per_barcode.png")
	fig.clf()
	
	############################################################################
	top10 = umis.loc[ umis.UMIs >= umis.UMIs.quantile(.9) ]
			
	mean_umis = pd\
		.DataFrame({
			"Barcodes": ["All", "Top 10 %"],
			"Count": [umis.UMIs.mean(), top10.UMIs.mean()]
		})
		
	bar_probes = sns.barplot(data=mean_umis, x="Barcodes", y="Count")
	bar_probes.set_title(
		"Mean UMIs per barcode ({:,} barcodes, {:,} UMIs)"\
			.format(umis.shape[0], umis.UMIs.sum())
	)
	fig = bar_probes.get_figure()
	fig.savefig(f"{name}.mean_umis_per_barcode.pdf")
	fig.savefig(f"{name}.mean_umis_per_barcode.png")
	fig.clf()
	
	############################################################################
	mapping = pd\
		.Series(probes)\
		.map(len)\
		.sort_values(ascending=False)\
		.reset_index()\
		.rename(columns={"level_0": "Barcode", "level_1": "UMI", 0: "Probes"})
	
	############################################################################
	n_mapping = mapping\
		.Probes\
		.value_counts()\
		.reindex(range(1, mapping.Probes.max()+1), fill_value=0)\
		.reset_index()\
		.rename(columns={"index": "Probes", "Probes": "Count"})
	
	############################################################################
	bar_probes = sns.barplot(data=n_mapping, x="Probes", y="Count")
	bar_probes.set_title(
		"Probes per UMI ({:,} UMIs)".format(n_mapping.Count.sum())
	)
	fig = bar_probes.get_figure()
	fig.savefig(f"{name}.probes_per_umi.pdf")
	fig.savefig(f"{name}.probes_per_umi.png")
	fig.clf()
	############################################################################
	
##########################
if __name__ == "__main__":
	path = sys.argv[1]
	name = sys.argv[2]
	count_umis(path, name)

