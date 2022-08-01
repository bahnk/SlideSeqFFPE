import java.nio.file.Paths

process umi_tools_deduplicate {

	tag { "${name}" }

	label "sequencing"

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/06_umi_tools_deduplicate/${filename}" }

	input:
		tuple val(metadata), path(bam), path(bai)

	output:
		tuple \
			val(metadata),
			path("${name}.umi_tools_deduplicate.bam"),
			path("${name}.umi_tools_deduplicate.bam.bai"),
			emit: bam
		tuple val(metadata), path("${name}.umi_tools_deduplicate.log"), emit: log
		tuple val(metadata), path("${name}.umi_tools_deduplicate_*"), emit: stats
		tuple val(metadata), path("Version"), emit: version

	script:

		name = metadata["name"]

		"""
		umi_tools dedup \
			--stdin=$bam \
			--stdout="${name}.umi_tools_deduplicate.bam" \
			--log="${name}.umi_tools_deduplicate.log" \
			--extract-umi-method=read_id \
			--umi-separator=_ \
			--per-cell \
			--output-stats="${name}.umi_tools_deduplicate"

		umi_tools --version > Version
		
		samtools index "${name}.umi_tools_deduplicate.bam"
		samtools --version >> Version
		"""
}

process umi_tools_count {

	tag { "${name}" }

	label "sequencing"

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/07_umi_tools_count/${filename}" }

	input:
		tuple val(metadata), path(bam), path(bai)

	output:
		tuple val(metadata), path("${name}.count.tsv"), emit: tsv
		tuple val(metadata), path("${name}.count.log"), emit: log
		tuple val(metadata), path("Version"), emit: version

	script:

		name = metadata["name"]

		"""
		umi_tools count \
			--stdin=$bam \
			--per-contig \
			--per-cell \
			--method=directional \
			--stdout="${name}.count.tsv" \
			--log="${name}.count.log"

		umi_tools --version > Version
		"""
}

