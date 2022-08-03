#!/usr/bin/python

# coding: utf-8

import matplotlib as mpl
import pandas as pd
import pysam
import seaborn as sns
import sys

mpl.use('Agg')
sns.set(rc={'figure.figsize':(8,8)})

##############################
def count_up(csv_path, name):#
##############################

	#csv_path = "results/10um_bead-prok/03_filter_out_bad_up_primer_sequence/10um_bead-prok.up_primer_metrics.csv"
	#name = "sample1"
	
	# load
	df = pd\
		.read_csv(csv_path, header=None, index_col=None)\
		.rename(columns={0: "Name", 1: "Process", 2: "UP primer check", 3: "Reads"})\
		.loc[:, ["UP primer check", "Reads"]]
	
	# reshape 
	df = df.set_index("UP primer check")
	total = df.loc["Total"].iloc[0]
	pass_up = df.loc["Pass"].iloc[0]
	df = df.reset_index()
	df = df.loc[ df["UP primer check"] != "Total" ]
	
	# plot
	bar_probes = sns.barplot(data=df, x="UP primer check", y="Reads")
	bar_probes.set_title(
		"UP primer sequence check ({:,} total, {:,} pass)"\
			.format(total, pass_up)
	)
	fig = bar_probes.get_figure()
	fig.savefig(f"{name}.up_primer_metrics.pdf")
	fig.savefig(f"{name}.up_primer_metrics.png")
	fig.clf()
	############################################################################
	
##########################
if __name__ == "__main__":
	path = sys.argv[1]
	name = sys.argv[2]
	count_up(path, name)

