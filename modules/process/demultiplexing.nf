import java.nio.file.Paths

process bcl2fastq {

	container "docker://scicomppublic/bcl2fastq:2.20.0"
	cpus 12

	publishDir Paths.get( params.output_dir , "demultiplexing" ),
		mode: "copy",
		overwrite: "true"

	input:
		tuple path(data_dir), path(sample_sheet)

	output:
		path "*.fastq.gz", emit: fastqs
		path "Reports", emit: reports
		path "Stats", emit: stats
		path "Version", emit: version

	script:

		"""
		bcl2fastq \
			--runfolder-dir $data_dir \
			--sample-sheet $sample_sheet \
			--output-dir . \
			--ignore-missing-bcls \
			--ignore-missing-filter \
			--barcode-mismatches 0 \
			--loading-threads $task.cpus \
			--processing-threads $task.cpus \
			--writing-threads $task.cpus

		bcl2fastq --version 2> Version
		"""
}

process merge_lanes {

	tag { "${name}" }

	input:
		tuple val(metadata), path(fastq1), path(fastq2)

	output:
		tuple \
			val(metadata),
			path("${name}_R1.fastq.gz"),
			path("${name}_R2.fastq.gz")

	script:

		name = metadata["name"]
		n1 = metadata["n_fastq_read1"]
		n2 = metadata["n_fastq_read2"]
		
		if ( n1 != n2 )
		{
			"""
			echo "Error: not the same number of FASTQ files for Read 1 and Read 2"
			echo "Read 1 has ${n1} ${fastq1.getClass()} files"
			echo "Read 2 has ${n2} files"
			"""
		}

		else if ( n1 == 1 )
		{
			"""
			echo "Read 1 has ${n1} file"
			echo "Read 2 has ${n2} file"
			echo "We copy the files"
			cp -v $fastq1 "${name}_R1.fastq.gz"
			cp -v $fastq2 "${name}_R2.fastq.gz"
			"""
		}

		else
		{
			"""
			echo "Read 1 has ${n1} files"
			echo "Read 2 has ${n2} files"
			echo "We merge the files"
			zcat $fastq1 | gzip -c > "${name}_R1.fastq.gz"
			zcat $fastq2 | gzip -c > "${name}_R2.fastq.gz"
			"""
		}
}

