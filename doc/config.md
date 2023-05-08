
# Pipeline configuration

The pipeline configuration is achieved with a [YAML](https://en.wikipedia.org/wiki/YAML) file.
It should look like that roughly:

```yaml

# config file for Slide-seq FFPE

sample_sheet: data/SampleSheet.csv
data_dir: data
probes_fasta: assets/probes.fasta
output_dir: results
reads_to_sample: 200000
minimum_length_read1: 41
maximum_errors_up_primer: 3
maximum_errors_bead_barcode: 3
five_prime_probe_adapter_length: 41
probe_length: 25

# be careful, this needs to be a map
pucks:
  Curio_A0008-021: A0008_021_BeadBarcodes.txt
```

A config file example can be downloaded [here](https://bioinformatics.crick.ac.uk/shiny/users/bahn/slideseqffpe/params.yml), or just do:

```bash
$ wget https://bioinformatics.crick.ac.uk/shiny/users/bahn/slideseqffpe/params.yml
$ ls
params.yml
```

## The parameters

 * `sample_sheet`: the path of the sample sheet (used for [demultiplexing](steps.md#demultiplexing))
 * `data_dir`: the path of the sequencing folder (used for [demultiplexing](steps.md#demultiplexing))
 * `probes_fasta`: the path (used to [create an index](steps.md#create-probe-index))
 * `reads_to_sample`: number of reads to subsample (we run the pipeline in parallel with the same number of reads for each sample)
 * `output_dir`: the path of the output directory that will contain the results
 * `minimum_length_read1`: minimum read length for Read 1 (should be 43)
 * `maximum_errors_up_primer`: maximum edit distance for a valid UP primer (3 is good but can be higher)
 * `maximum_errors_bead_barcode`: maximum edit distance for bead barcode matching
 * `five_prime_probe_adapter_length`: the length of the 5' prime probe adapter  in Read 2
 * `probe_length`: the length of the probes sequences
 * `pucks`: a **map** containing `relative path` to spatial information for each sample. Map's keys should be sample names in `sample_sheet`. Spatial information should be a file formatted the [Curio way](https://curiobioscience.com/support/barcode/)


## The `probes_fasta` parameter

A FASTA file for the probes we currently use can be downloaded [here](https://bioinformatics.crick.ac.uk/shiny/users/bahn/slideseqffpe/probes.fasta), or just do:

```bash
$ wget https://bioinformatics.crick.ac.uk/shiny/users/bahn/slideseqffpe/probes.fasta
$ ls
probes.fasta
```

