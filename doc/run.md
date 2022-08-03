
# Running the pipeline

Just `ssh` to camp and open terminal demultiplexer (`tmux` or `screen`) if you use one.

Then, be sure that your singularity config directory is not in your home.
For example:

```bash
$ ls -l ~/.singularity
lrwxrwxrwx 1 username domain users 40 Aug 26  2021 /camp/home/username/.singularity -> /camp/stp/babs/working/username/.singularity
```

You can now download the probe sequences FASTA file by running:

```bash
$ wget https://bioinformatics.crick.ac.uk/shiny/users/bahn/slideseqffpe/probes.fasta
$ ls
probes.fasta
```

After that download an example parameter file:

```bash
$ wget https://bioinformatics.crick.ac.uk/shiny/users/bahn/slideseqffpe/params.yml
$ ls
params.yml
$ cat params.yml

# config file for Slide-seq FFPE

sample_sheet: data/SampleSheet.csv
data_dir: data
probes_fasta: probes.fasta
output_dir: results
minimum_length_read1: 43
maximum_errors_up_primer: 3
five_prime_probe_adapter_length: 38
probe_length: 31

```

Now, you need to parametrise the pipeline as detailed [here](config.md).
You can either edit the `params.yml` or you can overwrite the parameters with the command line as explained later.
Normally, you should only have to change the `sample_sheet` and `data_dir` parameters.

We need to load these two modules before running the pipeline:

```bash
module load Nextflow/22.04.0 Singularity/3.6.4
```

Then, pull the latest version of the pipeline:
```bash
nextflow pull bahnk/SlideSeqFFPE
```

Finally, you can run the pipeline this way:

```bash
nextflow run bahnk/SlideSeqFFPE -r main -params-file params.yml
```

Alternatively, if you don't want to edit the `params.yml` file, then you can overwrite the parameters this way:

```bash
nextflow run bahnk/SlideSeqFFPE -r main -params-file params.yml --sample_sheet /path/to/samplesheet --data_dir /path/to/sequencingdirectory
```
