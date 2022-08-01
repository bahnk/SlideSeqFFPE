
# Pipeline output

The output of the pipeline should be in the directory specified by the `output_dir` parameter in the [parameter file](config.md).

Each sample has its own directory based on its name.
Otherwise, you shoud find a `demultiplexing` directory, a `probe_index` directory that contains the probes index, and the output of [MultiQC](https://multiqc.info) (`multiqc_report.html` and `multiqc_data`):

```bash
$ ls -l results 
total 1547
drwxr-xr-x 10 bahn domain users    4096 Jul 29 11:53 10um_bead-prok
drwxr-xr-x 10 bahn domain users    4096 Jul 29 11:53 10um_RNase1
drwxr-xr-x 10 bahn domain users    4096 Jul 29 11:53 10um_RNase2
drwxr-xr-x 10 bahn domain users    4096 Jul 29 11:53 10um_std
drwxr-xr-x 10 bahn domain users    4096 Jul 29 11:53 5um_bead-prok
drwxr-xr-x 10 bahn domain users    4096 Jul 29 11:53 5um_RNase1
drwxr-xr-x 10 bahn domain users    4096 Jul 29 11:53 5um_RNase2
drwxr-xr-x 10 bahn domain users    4096 Jul 29 11:53 5um_std
drwxr-xr-x  4 bahn domain users    4096 Jul 29 16:08 demultiplexing
drwxr-xr-x  2 bahn domain users    4096 Jul 29 16:09 multiqc_data
-rwxr-xr-x  1 bahn domain users 1340399 Jul 29 16:09 multiqc_report.html
drwxr-xr-x  2 bahn domain users    4096 Jul 29 16:08 probe_index
```

In each sample directory, you should find the output files of each step detailed [here](steps.md) organised by order.


```bash
$ ls -l results/10um_bead-prok
total 8
drwxr-xr-x 2 bahn domain users 4096 Jul 29 16:08 00_fastqc
drwxr-xr-x 2 bahn domain users 4096 Jul 29 16:08 01_filter_out_too_short_read1
drwxr-xr-x 2 bahn domain users 4096 Jul 29 16:08 02_extract_barcode_and_umi
drwxr-xr-x 2 bahn domain users 4096 Jul 29 16:08 03_filter_out_bad_up_primer_sequence
drwxr-xr-x 2 bahn domain users 4096 Jul 29 16:08 04_extract_probe_sequence
drwxr-xr-x 2 bahn domain users 4096 Jul 29 16:08 05_align_probe
drwxr-xr-x 2 bahn domain users 4096 Jul 29 16:08 06_umi_tools_deduplicate
drwxr-xr-x 2 bahn domain users 4096 Jul 29 16:08 07_umi_tools_count
```

The count matrix can be found in the `07_umi_tools_count` folder:

```bash
$ ls -l results/10um_bead-prok/07_umi_tools_count
total 6401
-rwxr-xr-x 1 bahn domain users    3615 Jul 29 16:08 10um_bead-prok.count.log
-rwxr-xr-x 1 bahn domain users 6342321 Jul 29 16:08 10um_bead-prok.count.tsv
```

The count matrix is the sample name with the `.count.tsv` suffix:

```bash
$ head results/10um_bead-prok/07_umi_tools_count/10um_bead-prok.count.tsv
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

