import java.nio.file.Paths

process count_reads {

	tag { "${name}" }

	label "sequencing"

	time "03:00:00"

	input:
		tuple val(metadata), path(read1), path(read2)

	output:
		tuple val(metadata), stdout

	script:

		name = metadata["name"]

		"""
		zcat $read1 | sed -n '1~4p' | wc -l
		"""
}
process subsample {

	tag { "${name}" }

	label "sequencing"

	time "03:00:00"
	//memory "300G"

	publishDir Paths.get( params.output_dir , "subsampling" ),
		mode: "copy",
		overwrite: "true"

	input:
		tuple val(metadata), path(read1), path(read2)

	output:
		tuple	val(metadata), path("${name}_R1.fastq.gz"), path("${name}_R2.fastq.gz")

	script:

		name = metadata["name"]
		min_reads = metadata["min_reads"]

		"""
		seqtk sample -s100 $read1 $min_reads | gzip -c > "${name}_R1.fastq.gz"
		seqtk sample -s100 $read2 $min_reads | gzip -c > "${name}_R2.fastq.gz"
		"""
}

