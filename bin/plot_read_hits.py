#!/usr/bin/python

# coding: utf-8

import matplotlib as mpl
import pandas as pd
import pysam
import seaborn as sns
import sys

mpl.use('Agg')
sns.set(rc={'figure.figsize':(8,8)})

################################
def count_hits(csv_path, name):#
################################

	#csv_path = "results/10um_bead-prok/05_align_probe/10um_bead-prok.hits.csv"
	#name = "sample1"
	
	# load
	df = pd\
		.read_csv(csv_path, header=None, index_col=None)\
		.rename(columns={0: "Probes", 1: "Reads"})
	
	# reshape
	df = df\
		.set_index("Probes")\
		.reindex(range(1, df.Probes.max()+1), fill_value=0)\
		.reset_index()
	
	# plot
	bar_probes = sns.barplot(data=df, x="Probes", y="Reads")
	bar_probes.set_title(
		"Probes mapped by a read ({:,} total)"\
			.format(df.Reads.sum())
	)
	fig = bar_probes.get_figure()
	fig.savefig(f"{name}.hits.pdf")
	fig.savefig(f"{name}.hits.png")
	fig.clf()
	############################################################################
	
##########################
if __name__ == "__main__":
	path = sys.argv[1]
	name = sys.argv[2]
	count_hits(path, name)

