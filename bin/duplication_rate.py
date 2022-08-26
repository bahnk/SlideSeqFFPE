#!/usr/bin/python

# coding: utf-8

import matplotlib as mpl
import numpy as np
import pandas as pd
import seaborn as sns
import sys

mpl.use('Agg')
sns.set(rc={'figure.figsize':(8,8)})

#############################################################
def DupRate(name, umi_groups_path, bcd_groups_path, suffix):#
#############################################################

	#umi_groups_path = "results/10um_bead-prok/06_umi_tools_group/10um_bead-prok.umi_tools_group.tsv"
	#bcd_groups_path = "results/10um_bead-prok/07_umi_tools_group_barcodes/10um_bead-prok.umi_tools_group_barcodes.tsv"
	#name = "tmp/test"
	#suffix = "dup_rate"
	
	###########################################################################
	
	# load
	umi_groups = pd.read_csv(umi_groups_path, sep="\t")
	bcd_groups = pd.read_csv(bcd_groups_path, sep="\t")
	
	# join
	df = pd.merge(
		left=umi_groups,
		right=bcd_groups,
		how="inner",
		on="read_id",
		suffixes=("_umi", "_bcd")
	)
	
	# count duplicated reads
	non_dup_reads_total = df\
		.loc[:,["final_umi_umi", "final_umi_bcd", "gene_umi"]]\
		.drop_duplicates()\
		.shape[0]
	dup_reads_total = df.shape[0] - non_dup_reads_total
	reads = pd\
		.DataFrame({
			"Reads": ["Non duplicate", "Duplicate"],
			"Count": [non_dup_reads_total, dup_reads_total]
		})\
		.assign(Frequency=lambda x: (x.Count / x.Count.sum() * 100).round(1))\
		.assign(Name=name) \
		.assign(Process="Count")\
		.loc[:,["Name", "Process", "Reads", "Count"]]
	reads.to_csv(f"{name}.{suffix}.duplicated_reads_count.csv",
		index=False, header=False)
	
	# plot duplicated reads count
	reads_plot = sns.barplot(data=reads, x="Reads", y="Count")
	reads_plot.set_title(
		"Duplicated reads ({:,} total, {:,} not duplicates)"\
			.format(reads.Count.sum(), non_dup_reads_total)
	)
	fig = reads_plot.get_figure()
	fig.savefig(f"{name}.{suffix}.duplicated_reads_count.pdf")
	fig.savefig(f"{name}.{suffix}.duplicated_reads_count.png")
	fig.clf()
	
	# corrected barcodes
	barcodes = df\
		.loc[ df.umi_bcd != df.final_umi_bcd ]\
		.loc[:,["umi_bcd", "final_umi_bcd", "umi_umi", "gene_bcd"]]\
		.drop_duplicates()\
		.sort_values(["final_umi_bcd", "umi_umi", "gene_bcd"])\
		.rename(columns={
			"umi_bcd": "Barcode",
			"final_umi_bcd": "NewBarcode",
			"umi_umi": "UMI",
			"gene_bcd": "Probe"
		})
	barcodes.to_csv(f"{name}.{suffix}.corrected_barcodes.csv", index=False)
	
	# umis per barcodes
	umis = df\
		.loc[:,["final_umi_umi", "final_umi_bcd", "gene_umi"]]\
		.drop_duplicates()\
		.groupby("final_umi_bcd")\
		.apply(lambda x: x.shape[0])\
		.reset_index()\
		.rename(columns={"final_umi_bcd": "Barcode", 0: "UMIs"})
	
	# plot umis per barcodes
	threshold = umis.UMIs.quantile(.9)
	
	top10 = umis.loc[ umis.UMIs >= threshold ]
			
	mean_umis = pd\
		.DataFrame({
			"Barcodes": ["All", "Top 10 %"],
			"Mean": [round(umis.UMIs.mean(), 2), round(top10.UMIs.mean(), 2)]
		})\
		.assign(Name=name)\
		.assign(Process="Count")\
		.loc[:,["Name", "Process", "Barcodes", "Mean"]]
	mean_umis.to_csv(f"{name}.{suffix}.mean_umis_per_barcode.csv",
		index=False, header=False)
	
		
	umis_plot = sns.barplot(data=mean_umis, x="Barcodes", y="Mean")
	umis_plot.set_title(
		"Mean UMIs per barcode after deduplication\n({:,} reads {:,} barcodes, {:,} UMIs, threshold: {:,})"\
		.format(non_dup_reads_total, umis.shape[0], umis.UMIs.sum(), round(threshold, 1))
	)
	fig = umis_plot.get_figure()
	fig.savefig(f"{name}.{suffix}.mean_umis_per_barcode.pdf")
	fig.savefig(f"{name}.{suffix}.mean_umis_per_barcode.png")
	fig.clf()
	############################################################################

##########################
if __name__ == "__main__":
	DupRate(
		name=sys.argv[1],
		umi_groups_path=sys.argv[2],
		bcd_groups_path=sys.argv[3],
		suffix=sys.argv[4]
	)

