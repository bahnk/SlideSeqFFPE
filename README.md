
# Slide-seq FFPE


Here is the documentation:

 1. [Pipeline steps](doc/steps.md)
 2. [Pipeline configuration](doc/config.md)
 3. [Running the pipeline](doc/run.md)
 4. [Pipeline output](doc/output.md)

In a nutshell, you can just run:

```bash
# download the example parmeters file and the probe sequences
wget https://bioinformatics.crick.ac.uk/shiny/users/bahn/slideseqffpe/params.yml
wget https://bioinformatics.crick.ac.uk/shiny/users/bahn/slideseqffpe/probes.fasta

# load nextflow and singularity
module load Nextflow/22.04.0 Singularity/3.6.4

# run the pipeline and pray
nextflow run bahnk/SlideSeqFFPE -r main -params-file params.yml --sample_sheet /path/to/samplesheet --data_dir /path/to/sequencingdirectory
```

