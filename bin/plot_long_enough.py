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

	#csv_path = "results/10um_bead-prok/01_filter_out_too_short_read1/10um_bead-prok.long_enough_read1.csv"
	#name = "sample1"
	
	# load
	df = pd\
		.read_csv(csv_path, header=None, index_col=None)\
		.rename(columns={0: "Name", 1: "Process", 2: "Read", 3: "Reads"})\
		.loc[:, ["Read", "Reads"]]
	
	# reshape 
	df = df.set_index("Read")
	df.loc["Too short"] = df.loc["Total"] - df.loc["Long enough"]
	total = df.loc["Total"].iloc[0]
	long_enough = df.loc["Long enough"].iloc[0]
	df = df.reset_index()
	df = df.loc[ df.Read != "Total" ]
	
	# plot
	bar_probes = sns.barplot(data=df, x="Read", y="Reads")
	bar_probes.set_title(
		"Long enough reads 1 ({:,} total, {:,} long enough)"\
			.format(total, long_enough)
	)
	fig = bar_probes.get_figure()
	fig.savefig(f"{name}.filter_out_too_short_read1.pdf")
	fig.savefig(f"{name}.filter_out_too_short_read1.png")
	fig.clf()
	############################################################################
	
##########################
if __name__ == "__main__":
	path = sys.argv[1]
	name = sys.argv[2]
	count_read1(path, name)

