import java.nio.file.Paths

process filter_out_too_short_read1 {

	tag { "${name}" }

	label "sequencing"
	cpus 12

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/01_filter_out_too_short_read1/${filename}" }

	input:
		tuple val(metadata), path(fastq1), path(fastq2)

	output:
		tuple val(metadata),
			path("${name}.long_enough_read1.R1.fastq.gz"),
			path("${name}.long_enough_read1.R2.fastq.gz"),
			emit: fastqs
		tuple val(metadata), path("${name}.cutadapt.filter_out_too_short_read1.log"), emit: log
		tuple val(metadata), path("Version"), emit: version

	script:

		name = metadata["name"]

		"""
		cutadapt \
			--minimum-length=$params.minimum_length_read1 \
			--pair-filter=first \
			--output="${name}.long_enough_read1.R1.fastq.gz" \
			--paired-output="${name}.long_enough_read1.R2.fastq.gz" \
			--cores=$task.cpus \
			$fastq1 $fastq2 \
			> "${name}.cutadapt.filter_out_too_short_read1.log"

		cutadapt --version > Version
		"""
}

process extract_barcode_and_umi {

	tag { "${name}" }

	label "sequencing"

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/02_extract_barcode_and_umi/${filename}" }

	input:
		tuple val(metadata), path(fastq1), path(fastq2)

	output:
		tuple val(metadata),
			path("${name}.extract_barcode_umi.R1.fastq.gz"),
			path("${name}.extract_barcode_umi.R2.fastq.gz"),
			emit: fastqs
		tuple val(metadata),
			path("${name}.failed_extraction.R1.fastq.gz"),
			path("${name}.failed_extraction.R2.fastq.gz"),
			emit: failed
		tuple val(metadata), path("${name}.umi_tools.extract.log"), emit: log
		tuple val(metadata), path("Version"), emit: version

	script:

		name = metadata["name"]
		regex = "^(?P<cell_1>.{1,8}).{1,18}(?P<cell_2>.{1,6})(?P<discard_2>.{1,3})(?P<umi_1>.{1,8})(?<discard_1>.*)"

		"""
		umi_tools extract \
			--stdin=$fastq1 \
			--read2-in=$fastq2 \
			--stdout="${name}.extract_barcode_umi.R1.fastq.gz" \
			--read2-out="${name}.extract_barcode_umi.R2.fastq.gz" \
			--extract-method=regex \
			--bc-pattern="${regex}" \
			--filtered-out="${name}.failed_extraction.R1.fastq.gz" \
			--filtered-out2="${name}.failed_extraction.R2.fastq.gz" \
			--log="${name}.umi_tools.extract.log"

		umi_tools --version > Version
		"""
}

process filter_out_bad_up_primer {

	tag { "${name}" }

	label "python"

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/03_filter_out_bad_up_primer_sequence/${filename}" }

	input:
		tuple val(metadata), path(fastq1), path(fastq2), path(script)

	output:
		tuple val(metadata), path("${name}.up_primer_pass.fastq.gz"), emit: pass
		tuple val(metadata), path("${name}.up_primer_fail.fastq.gz"), emit: fail

	script:

		name = metadata["name"]

		"""
		python3 $script "${name}" $fastq1 $fastq2 $params.maximum_errors_up_primer
		"""
}

process extract_probe_sequence {

	tag { "${name}" }

	label "sequencing"

	cpus 12

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/04_extract_probe_sequence/${filename}" }

	input:
		tuple val(metadata), path(fastq)

	output:
		tuple val(metadata), path("${name}.probe_extracted.fastq.gz"), emit: fastq
		tuple val(metadata), path("${name}.5prime_trimmed.fastq.gz"), emit: five_prime
		tuple val(metadata), path("Version"), emit: version

	script:

		name = metadata["name"]

		"""
		seqtk trimfq \
			-b $params.five_prime_probe_adapter_length \
			$fastq \
			| gzip -c > "${name}.5prime_trimmed.fastq.gz"

		cutadapt \
			--cores $task.cpus \
			--length $params.probe_length \
			-o "${name}.probe_extracted.fastq.gz" \
			"${name}.5prime_trimmed.fastq.gz"

		seqtk 2>&1 | grep -i version | awk '{ print "seqtk " \$0 }' > Version
		cutadapt --version | awk '{ print "cudadapt version " \$0 }' >> Version
		"""
}

