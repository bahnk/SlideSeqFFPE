
# Slide-seq FFPE


Here is the documentation:

 1. [Pipeline steps](doc/steps.md)
 2. [Pipeline configuration](doc/config.md)
 3. [Running the pipeline](doc/run.md)
 4. [Pipeline output](doc/output.md)

In a nutshell, first be sure that your singularity config directory is not in your home.
For example:

```bash
$ ls -l ~/.singularity
lrwxrwxrwx 1 username domain users 40 Aug 26  2021 /camp/home/username/.singularity -> /camp/stp/babs/working/username/.singularity
```

Then, you can just run:

```bash
# download the example parmeters file and the probe sequences
wget https://bioinformatics.crick.ac.uk/shiny/users/bahn/slideseqffpe/params.yml
wget https://bioinformatics.crick.ac.uk/shiny/users/bahn/slideseqffpe/probes.fasta
wget https://bioinformatics.crick.ac.uk/shiny/users/bahn/slideseqffpe/template.fasta

# load nextflow and singularity
module load Nextflow/22.04.0 Singularity/3.6.4

# pull the latest version
nextflow pull bahnk/SlideSeqFFPE -r spatial

# run the pipeline and pray
nextflow run bahnk/SlideSeqFFPE -r spatial -params-file params.yml --sample_sheet /path/to/samplesheet --data_dir /path/to/sequencingdirectory
```

If you're on NEMO, you need to create a configuration file named `singularity.config`with the following content:

```
singularity {
	enabled = true
	runOptions = "-B /nemo --nv"
}
```

Then, pass this configuration file to nextflow when you run the pipeline:

```
nextflow -c singularity.config run bahnk/SlideSeqFFPE -r spatial -params-file params.yml --sample_sheet /path/to/samplesheet --data_dir /path/to/sequencingdirectory
```

