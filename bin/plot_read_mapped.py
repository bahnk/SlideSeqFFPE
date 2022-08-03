#!/usr/bin/python

# coding: utf-8

import matplotlib as mpl
import pandas as pd
import pysam
import seaborn as sns
import sys

mpl.use('Agg')
sns.set(rc={'figure.figsize':(8,8)})

###################################
def count_mapping(csv_path, name):#
###################################

	#csv_path = "results/10um_bead-prok/05_align_probe/10um_bead-prok.mapped.csv"
	#name = "sample1"
	
	# load
	df = pd\
		.read_csv(csv_path, header=None, index_col=None)\
		.rename(columns={0: "Mapping", 1: "Reads"})
	
	# plot
	bar_probes = sns.barplot(data=df, x="Mapping", y="Reads")
	bar_probes.set_title(
		"Read mapping a probe ({:,} total, {:,} mapped)"\
			.format(df.Reads.sum(), df.set_index("Mapping").loc["Mapped"].iloc[0])
	)
	fig = bar_probes.get_figure()
	fig.savefig(f"{name}.mapped.pdf")
	fig.savefig(f"{name}.mapped.png")
	fig.clf()
	############################################################################
	
##########################
if __name__ == "__main__":
	path = sys.argv[1]
	name = sys.argv[2]
	count_mapping(path, name)

