#!/usr/bin/python

# coding: utf-8

from os import listdir
from os.path import join
import pandas as pd
import sys

####################################
def ExportMetrics(name, directory):#
####################################

	#directory = "tmp/csv"
	#name = "tmp/metrics"

	###########################################################################

	# load
	dfs = []
	for f in listdir(directory):
		if f.endswith(".csv"):
			dfs.append( pd.read_csv(join(directory, f), header=None) )
	
	# to wide format
	df = pd\
		.concat(dfs)\
		.rename(columns={0:"Name", 1:"Process", 2:"Metric", 3:"Value"})\
		.set_index(["Process", "Metric", "Name"])\
		.unstack("Name")
	
	# reads raw counts
	counts = df\
		.loc[[
			("Read 1 length", "Total"),
			("Read 1 length", "Long enough"),
			("Barcode/UMI extraction", "Success"),
			("UP primer", "Pass"),
			("Probe extraction", "Shortened"),
			("Alignment", "Mapped"),
			("Count", "Non duplicate")
		]]
	counts.columns = counts.columns.droplevel()
	index = pd.DataFrame({
		"Step": list(range(1, 8)),
		"Read count": [
			"Total reads",
			"Read1 long enough",
			"Barcode/UMI extraction on Read1",
			"Good UP primer",
			"Probe extraction on Read2",
			"Read2 maps a probe sequence",
			"Non duplicate"
		]
	})
	counts.index = pd.MultiIndex.from_frame(index)
	counts\
		.astype(int)\
		.reset_index()\
		.to_csv(f"{name}.read_counts.csv", index=False)
	
	# reads percentages
	percent = counts.apply(lambda x: ( x / x.iloc[0] * 100 ).round(2), axis=0)
	percent.reset_index().to_csv(f"{name}.read_percent.csv", index=False)
	
	# mean umis
	umis = df\
		.loc[[
			("Count", "All"),
			("Count", "Top 10 %")
		]]
	umis.index = umis.index.droplevel()
	umis.columns = umis.columns.droplevel()
	umis.reset_index().to_csv(f"{name}.umis_per_barcode.csv", index=False)
	
	# duplicates
	dups = df\
		.loc[[
			("Count", "Duplicate"),
			("Count", "Non duplicate")
		]]
	dups.index = dups.index.droplevel()
	dups.columns = dups.columns.droplevel()
	dups.loc["Percent duplicates"] = (dups.loc["Duplicate"] / dups.apply(sum) * 100).round(2)
	dups\
		.loc["Percent duplicates"]\
		.to_frame()\
		.T\
		.reset_index()\
		.rename(columns={"index": "Metric"})\
		.to_csv(f"{name}.duplicates_percent.csv", index=False)
	###########################################################################

##########################
if __name__ == "__main__":
	name = sys.argv[1]
	directory = sys.argv[2]
	ExportMetrics(name, directory)

