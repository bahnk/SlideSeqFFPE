#!/usr/bin/python

# coding: utf-8

import matplotlib as mpl
import pandas as pd
import pysam
import seaborn as sns
import sys

mpl.use('Agg')
sns.set(rc={'figure.figsize':(8,8)})

#################################
def count_read1(csv_path, name):#
#################################

	#csv_path = "results/Sample_1/04_extract_probe_sequence/Sample_1.probe_extraction.csv"
	#name = "tmp/sample1"
	
	# load
	df = pd\
		.read_csv(csv_path, header=None, index_col=None)\
		.rename(columns={0: "Name", 1: "Process", 2: "Read", 3: "Reads"})\
		.loc[:, ["Read", "Reads"]]
	
	# reshape 
	df["Read"] = df["Read"].str.replace("Pass", "Good")
	df = df.set_index("Read")
	total = df.loc["Total"].iloc[0]
	long_enough = df.loc["Good"].iloc[0]
	df = df.reset_index()
	df = df.loc[ df.Read != "Total" ]
	
	# plot
	bar_probes = sns.barplot(data=df, x="Read", y="Reads")
	bar_probes.set_title(
		"Extracted probes ({:,} good reads and {:,} total)"\
			.format(long_enough, total)
	)
	fig = bar_probes.get_figure()
	fig.savefig(f"{name}.probe_extraction.pdf")
	fig.savefig(f"{name}.probe_extraction.png")
	fig.clf()
	############################################################################
	
##########################
if __name__ == "__main__":
	path = sys.argv[1]
	name = sys.argv[2]
	count_read1(path, name)

