#!/usr/bin/python

# coding: utf-8

import sys
import numpy as np
import pandas as pd
from matplotlib.figure import Figure

import matplotlib as mpl
mpl.rc('font', size=16)

#count_path = "Curio_A0008-021.count.tsv"
#spatial_path = "A0008_021_BeadBarcodes.txt"
#hamming_path = "output.csv"
#max_distance = 3
#base_path = "result"

count_path = sys.argv[1]
spatial_path = sys.argv[2]
hamming_path = sys.argv[3]
max_distance = int(sys.argv[4])
base_path = sys.argv[5]

# digital expression matrix
count = pd.read_csv(count_path, sep="\t")

# coordinates
spatial = pd\
	.read_csv(spatial_path, sep="\t", header=None)\
	.set_axis(["barcode", "x", "y"], axis="columns", inplace=False)

# hamming distances
hamming = pd\
	.read_csv(hamming_path, header=None)\
	.set_axis(
		["seq_barcode", "min_distance", "matches", "puck_barcodes"],
		axis="columns",
		inplace=False
	)

# puck barcodes for which we already found and sequencing barcode
blacklist = set()
mapping = {}

for distance in range(max_distance+1):

	# current distance with only one match and not assigned already
	current_dist = hamming[ hamming.min_distance == distance ]
	uniq = current_dist[ current_dist.matches == 1 ]
	unassigned = uniq[ ~ uniq.puck_barcodes.isin(blacklist) ]

	# remove potential conflicts
	conflicts = (unassigned.puck_barcodes.value_counts() > 1)\
		.reset_index()\
		.query("puck_barcodes == True")\
		.iloc[:,0]\
		.to_list()
	conflicts = set(conflicts)
	df = unassigned[ ~ unassigned.puck_barcodes.isin(conflicts) ]

	# update black list with assigned barcodes and conflicts
	blacklist = blacklist.union( set(df.puck_barcodes) )
	blacklist = blacklist.union(conflicts)

	# update mapping
	mapping = {
		**mapping,
		**df.set_index("seq_barcode")["puck_barcodes"].to_dict()
	}

# final mapping
dge = pd\
	.Series(mapping)\
	.reset_index()\
	.set_axis(["cell", "barcode"], axis="columns", inplace=False)\
	.merge(spatial, how="left")\
	.merge(count, how="inner")
dge.to_csv(f"{base_path}.dge.csv", index=False)

# UMIs
umis = dge\
	.groupby(["cell", "x", "y"])\
	.apply(lambda x: x["count"].sum())\
	.rename("count")\
	.reset_index()

# plot
fig = Figure(figsize=(8,8))
ax = fig.add_subplot(111)
c = ax.scatter(
		umis.x, umis.y,
		c=umis["count"],
		s=1,
		cmap="viridis_r",
		norm=mpl.colors.Normalize(
			0,
			np.percentile(umis["count"], 95),
			clip=True
		)
)
c.set_rasterized(True)
ax.set_xlabel("X")
ax.set_ylabel("Y")
ax.axis("equal")
ax.set_title("UMIs per bead")
fig.colorbar(c, ax=ax)
fig.tight_layout()
fig.savefig(f"{base_path}.umis.png")
fig.savefig(f"{base_path}.umis.pdf")

