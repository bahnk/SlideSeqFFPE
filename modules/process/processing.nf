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
			path("${name}.${suffix}.R1.fastq.gz"),
			path("${name}.${suffix}.R2.fastq.gz"),
			emit: fastqs
		tuple val(metadata), path("${name}.cutadapt.filter_out_too_short_read1.log"), emit: log
		tuple val(metadata), path("Version"), emit: version
		tuple val(metadata), path("${name}.${suffix}.csv"), emit: metrics

	script:

		name = metadata["name"]
		suffix = "long_enough_read1"

		"""
		cutadapt \
			--minimum-length=$params.minimum_length_read1 \
			--pair-filter=first \
			--output="${name}.${suffix}.R1.fastq.gz" \
			--paired-output="${name}.${suffix}.R2.fastq.gz" \
			--cores=$task.cpus \
			$fastq1 $fastq2 \
			> "${name}.cutadapt.filter_out_too_short_read1.log"

		cutadapt --version > Version

		zcat $fastq1 \
			| sed -n "2~4p" \
			| wc -l \
			| awk '{ printf "%s,%s,%s,%s\\n", "${name}", "Read 1 length", "Total", \$0 }' \
			> "${name}.${suffix}.csv" 

		zcat "${name}.${suffix}.R1.fastq.gz" \
			| sed -n "2~4p" \
			| wc -l \
			| awk '{ printf "%s,%s,%s,%s\\n", "${name}", "Read 1 length", "Long enough", \$0 }' \
			>> "${name}.${suffix}.csv" 
		"""
}

process plot_filter_out_too_short_read1 {

	tag { "${name}" }

	label "python"

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/01_filter_out_too_short_read1/${filename}" }

	input:
		tuple val(metadata), path(csv), path(script)

	output:
		tuple val(metadata), path("${name}.filter_out_too_short_read1.pdf"), emit: pdf
		tuple val(metadata), path("${name}.filter_out_too_short_read1.png"), emit: png

	script:

		name = metadata["name"]

		"""
		python3 $script $csv "${name}"
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
			path("${name}.${suffix}.R1.fastq.gz"),
			path("${name}.${suffix}.R2.fastq.gz"),
			emit: fastqs
		tuple val(metadata),
			path("${name}.failed_extraction.R1.fastq.gz"),
			path("${name}.failed_extraction.R2.fastq.gz"),
			emit: failed
		tuple val(metadata), path("${name}.umi_tools.extract.log"), emit: log
		tuple val(metadata), path("Version"), emit: version
		tuple val(metadata), path("${name}.${suffix}.csv"), emit: metrics

	script:

		name = metadata["name"]
		regex = "^(?P<cell_1>.{1,8}).{1,18}(?P<cell_2>.{1,6})(?P<umi_1>.{1,9})(?<discard_1>.*)"
		suffix = "extract_barcode_umi"

		"""
		umi_tools extract \
			--stdin=$fastq1 \
			--read2-in=$fastq2 \
			--stdout="${name}.${suffix}.R1.fastq.gz" \
			--read2-out="${name}.${suffix}.R2.fastq.gz" \
			--extract-method=regex \
			--bc-pattern="${regex}" \
			--filtered-out="${name}.failed_extraction.R1.fastq.gz" \
			--filtered-out2="${name}.failed_extraction.R2.fastq.gz" \
			--log="${name}.umi_tools.extract.log"

		umi_tools --version > Version

		zcat $fastq1 \
			| sed -n "2~4p" \
			| wc -l \
			| awk '{ printf "%s,%s,%s,%s\\n", "${name}", "Barcode/UMI extraction", "Total", \$0 }' \
			> "${name}.${suffix}.csv"

		zcat "${name}.${suffix}.R1.fastq.gz" \
			| sed -n "2~4p" \
			| wc -l \
			| awk '{ printf "%s,%s,%s,%s\\n", "${name}", "Barcode/UMI extraction", "Success", \$0 }' \
			>> "${name}.${suffix}.csv"

		zcat "${name}.failed_extraction.R1.fastq.gz" \
			| sed -n "2~4p" \
			| wc -l \
			| awk '{ printf "%s,%s,%s,%s\\n", "${name}", "Barcode/UMI extraction", "Failure", \$0 }' \
			>> "${name}.${suffix}.csv"
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
		tuple val(metadata), path(fastq1), path(fastq2), path(script), path(plot_script)

	output:
		tuple val(metadata), path("${name}.up_primer_pass.fastq.gz"), emit: pass
		tuple val(metadata), path("${name}.up_primer_fail.fastq.gz"), emit: fail
		tuple val(metadata), path("${name}.up_primer_metrics.csv"), emit: metrics
		tuple val(metadata), path("${name}.up_primer_metrics.pdf"), emit: pdf
		tuple val(metadata), path("${name}.up_primer_metrics.png"), emit: png

	script:

		name = metadata["name"]

		"""
		python3 $script "${name}" $fastq1 $fastq2 $params.maximum_errors_up_primer
		python3 $plot_script "${name}.up_primer_metrics.csv" "${name}"
		"""
}

process extract_probe_sequence {

	tag { "${name}" }

	label "python"

	cpus 12

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/04_extract_probe_sequence/${filename}" }

	input:
		tuple val(metadata), path(fastq), path(script), path(plot_script)

	output:
		tuple val(metadata), path("${name}.${suffix}.unmatched.fastq.gz"), emit: unmatched
		tuple val(metadata), path("${name}.${suffix}.too_short.fastq.gz"), emit: too_short
		tuple val(metadata), path("${name}.${suffix}.pass.fastq.gz"), emit: fastq
		tuple val(metadata), path("${name}.${suffix}.csv"), emit: metrics
		tuple val(metadata), path("${name}.${suffix}.pdf"), emit: pdf
		tuple val(metadata), path("${name}.${suffix}.png"), emit: png

	script:

		name = metadata["name"]
		suffix = "probe_extraction"

		"""
		python3 $script "${name}" $fastq

		python3 $plot_script "${name}.${suffix}.csv" "${name}"
		"""
}

