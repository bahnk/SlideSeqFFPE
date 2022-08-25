#!/usr/bin/python

# coding: utf-8

import matplotlib as mpl
import numpy as np
import pandas as pd
import seaborn as sns
import sys

mpl.use('Agg')
sns.set(rc={'figure.figsize':(8,8)})

########################################################
def DupRate(name, groups_path, whitelist_path, suffix):#
########################################################

	#groups_path = "results/10um_bead-prok/07_barcode_subsampling/10um_bead-prok.group_subsampled.tsv"
	#whitelist_path = "results/10um_bead-prok/08_collapse_barcodes/10um_bead-prok.collapse_barcodes.whitelist.tsv"
	#name = "tmp/test"
	#suffix = "collapse_barcodes"
	
	############################################################################
	
	# load
	groups = pd\
		.read_csv(groups_path, sep="\t")\
		.rename(columns={"barcode": "Barcode", "final_umi": "UMI"})
	wl = pd.read_csv(whitelist_path, sep="\t", header=None)
	
	# merge the barcodes of the same group
	wl["Barcode"] = np.where(
		wl[1].isna(),
		wl[0].apply(lambda x: [x]),
		wl[0].apply(lambda x: [x]) + wl[1].str.split(",")
	)
	wl["Group"] = wl.index
	wl["HasDuplicates"] = wl.Barcode.apply(len) > 1
	wl = wl.explode("Barcode")
	wl["Representative"] = wl[0] == wl["Barcode"]
	
	# add the groups to the whitelist
	groups = pd.merge(
		groups,
		wl[["Barcode", "Group", "HasDuplicates", "Representative"]],
		on="Barcode",
		how="left"
	)
	
	# duplicates are reads whose the UMI is not unique inside a group
	dup_reads = groups\
		.groupby("Group")\
		.apply(lambda x: x.UMI.duplicated(keep="first"))\
		.droplevel(0)
	groups["Duplicate"] = dup_reads.loc[ groups.index ]
	
	# save groups
	groups.to_csv(f"{name}.{suffix}.groups.csv", index=False, sep="\t")
	
	# count duplicated reads
	reads = groups\
		.Duplicate\
		.value_counts()\
		.reset_index()\
		.rename(columns={"index": "Status", "Duplicate": "Count"})\
		.assign(Reads=lambda x: np.where(x.Status, "Not duplicate", "Duplicate"))\
		.assign(Frequency=lambda x: (x.Count / x.Count.sum() * 100).round(1))\
		.filter(["Reads", "Count", "Frequency"], axis=1)
	reads.to_csv(f"{name}.{suffix}.duplicated_reads_count.csv", index=False)
	
	# plot duplicated reads count
	reads_plot = sns.barplot(data=reads, x="Reads", y="Count")
	reads_plot.set_title(
		"Duplicated reads ({:,} total, {:,} duplicates)"\
			.format(
				reads.Count.sum(),
				round(reads.set_index("Reads").loc["Duplicate"].Count)
			)
	)
	fig = reads_plot.get_figure()
	fig.savefig(f"{name}.{suffix}.duplicated_reads_count.pdf")
	fig.savefig(f"{name}.{suffix}.duplicated_reads_count.png")
	fig.clf()
	
	# data frame to visualize the common UMI in a barcode group
	dups = groups\
		.loc[ groups.HasDuplicates ]\
		.loc[:,["Group", "Barcode", "UMI"]]\
		.drop_duplicates()\
		.sort_values(["Group", "UMI", "Barcode"])
	dups["CommonUMI"] = dups\
		.groupby("Group")\
		.apply(lambda x: np.where(x.UMI.duplicated(keep=False), "Common", "Not common"))\
		.explode()\
		.values
	dups.to_csv(f"{name}.{suffix}.common_umis.csv", index=False)
	
	# count duplicated barcodes
	barcodes = groups\
		.loc[:,["Barcode", "HasDuplicates", "Representative"]]\
		.drop_duplicates()\
		.Representative\
		.value_counts()\
		.reset_index()\
		.rename(columns={"index": "Status", "Representative": "Count"})\
		.assign(Barcodes=lambda x: np.where(x.Status, "Not duplicate", "Duplicate"))\
		.assign(Frequency=lambda x: (x.Count / x.Count.sum() * 100).round(1))\
		.filter(["Barcodes", "Count", "Frequency"], axis=1)
	barcodes.to_csv(f"{name}.{suffix}.duplicated_barcodes_count.csv", index=False)
	
	# plot duplicated barcodes count
	barcodes_plot = sns.barplot(data=barcodes, x="Barcodes", y="Frequency")
	barcodes_plot.set_title("Percentage of duplicated barcodes")
	fig = barcodes_plot.get_figure()
	fig.savefig(f"{name}.{suffix}.duplicated_barcodes_count.pdf")
	fig.savefig(f"{name}.{suffix}.duplicated_barcodes_count.png")
	fig.clf()
	############################################################################

##########################
if __name__ == "__main__":
	DupRate(
		name=sys.argv[1],
		groups_path=sys.argv[2],
		whitelist_path=sys.argv[3],
		suffix=sys.argv[4]
	)

