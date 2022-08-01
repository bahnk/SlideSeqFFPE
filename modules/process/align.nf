import java.nio.file.Paths

process create_probe_index {

	label "sequencing"
	cpus 12

	publishDir Paths.get( params.output_dir , "probe_index" ),
		mode: "copy",
		overwrite: "true"

	input:
		path fasta

	output:
		path "index*", emit: index
		path "Version", emit: version

	script:

		"""
		bowtie2-build --threads $task.cpus $fasta index 
		bowtie2 --version > Version
		"""
}

process align_probe {

	tag { "${name}" }

	label "sequencing"
	cpus 12

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/05_align_probe/${filename}" }

	input:
		tuple val(metadata), path(fastq), path(index)

	output:
		tuple val(metadata), path("${name}.align.bam"), path("${name}.align.bam.bai"), emit: bam
		tuple val(metadata), path("${name}.align.log"), emit: log
		tuple val(metadata), path("${name}.align.samtools_stats.txt"), emit: stats
		tuple val(metadata), path("Version"), emit: version

	script:

		name = metadata["name"]

		"""
		bowtie2 \
			-x index \
			--threads $task.cpus \
			-S "${name}.align.sam" \
			$fastq \
			2> "${name}.align.log"
		bowtie2 --version > Version

		samtools sort "${name}.align.sam" > "${name}.align.bam"
		samtools index "${name}.align.bam"
		samtools stats "${name}.align.bam" > "${name}.align.samtools_stats.txt"
		samtools --version >> Version
		"""
}

