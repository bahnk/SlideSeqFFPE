
# Pipeline output

The output of the pipeline should be in the directory specified by the `output_dir` parameter in the [parameter file](config.md).

Each sample has its own directory based on its name.
Otherwise, you shoud find a `demultiplexing` directory, a `probe_index` directory that contains the probes index, and the output of [MultiQC](https://multiqc.info) (`multiqc_report.html` and `multiqc_data`):

```bash
$ ls -l results 
drwxr-xr-x 11 bahn domain users    4096 Aug 26 13:43 10um_bead-prok
drwxr-xr-x 11 bahn domain users    4096 Aug 26 13:43 10um_RNase1
drwxr-xr-x 11 bahn domain users    4096 Aug 26 13:43 10um_RNase2
drwxr-xr-x 11 bahn domain users    4096 Aug 26 13:43 10um_std
drwxr-xr-x 11 bahn domain users    4096 Aug 26 13:43 5um_bead-prok
drwxr-xr-x 11 bahn domain users    4096 Aug 26 13:43 5um_RNase1
drwxr-xr-x 11 bahn domain users    4096 Aug 26 13:43 5um_RNase2
drwxr-xr-x 11 bahn domain users    4096 Aug 26 13:43 5um_std
drwxr-xr-x  4 bahn domain users    4096 Aug 26 13:43 demultiplexing
-rwxr-xr-x  1 bahn domain users     165 Aug 26 13:43 metrics.duplicates_percent.csv
-rwxr-xr-x  1 bahn domain users     643 Aug 26 13:43 metrics.read_counts.csv
-rwxr-xr-x  1 bahn domain users     582 Aug 26 13:43 metrics.read_percent.csv
-rwxr-xr-x  1 bahn domain users     192 Aug 26 13:43 metrics.umis_per_barcode.csv
drwxr-xr-x  2 bahn domain users    4096 Aug 26 13:43 multiqc_data
-rwxr-xr-x  1 bahn domain users 1340399 Aug 26 13:43 multiqc_report.html
drwxr-xr-x  2 bahn domain users    4096 Aug 26 13:43 probe_index
```

In each sample directory, you should find the output files of each step detailed [here](steps.md) organised by order.


```bash
$ ls -l results/10um_bead-prok
drwxr-xr-x 2 bahn domain users   4096 Aug 26 13:43 00_fastqc
drwxr-xr-x 2 bahn domain users   4096 Aug 26 13:43 01_filter_out_too_short_read1
drwxr-xr-x 2 bahn domain users   4096 Aug 26 13:43 02_extract_barcode_and_umi
drwxr-xr-x 2 bahn domain users   4096 Aug 26 13:43 03_filter_out_bad_up_primer_sequence
drwxr-xr-x 2 bahn domain users   4096 Aug 26 13:43 04_extract_probe_sequence
drwxr-xr-x 2 bahn domain users   4096 Aug 26 13:43 05_align_probe
drwxr-xr-x 2 bahn domain users   4096 Aug 26 13:43 06_umi_tools_group
drwxr-xr-x 2 bahn domain users   4096 Aug 26 13:43 07_umi_tools_group_barcodes
drwxr-xr-x 2 bahn domain users   4096 Aug 26 13:43 08_umi_tools_count
-rwxr-xr-x 1 bahn domain users 101939 Aug 26 13:43 10um_bead-prok.pdf
```

The count matrix can be found in the `08_umi_tools_count` folder:

```bash
$ ls -l results/10um_bead-prok/07_umi_tools_count
total 6401
-rwxr-xr-x 1 bahn domain users    3615 Jul 29 16:08 10um_bead-prok.count.log
-rwxr-xr-x 1 bahn domain users 6342321 Jul 29 16:08 10um_bead-prok.count.tsv
```

The count matrix is the sample name with the `.count.tsv` suffix:

```bash
$ head results/10um_bead-prok/08_umi_tools_count/10um_bead-prok.count.tsv
gene    cell    count
Actb_1128       AAAAACTCGTTATC  1
Actb_1128       AAAACACGTAGCGC  1
Actb_1128       AAAACGGACTGCCG  1
Actb_1128       AAAACTGTTCACCT  1
Actb_1128       AAAAGCCTAGGCGA  1
Actb_1128       AAAAGGCCGAGTCC  1
Actb_1128       AAAATGTACCCCTC  1
Actb_1128       AAACCAACTTCCAG  1
Actb_1128       AAACGTGACACCAA  1
```

