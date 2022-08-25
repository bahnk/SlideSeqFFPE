import java.nio.file.Paths

process umi_tools_group {

	tag { "${name}" }

	label "sequencing"

	time "03:00:00"
	//memory "300G"

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/06_umi_tools_group/${filename}" }

	input:
		tuple val(metadata), path(bam), path(bai)

	output:
		tuple \
			val(metadata),
			path("${name}.${suffix}.bam"),
			path("${name}.${suffix}.bam.bai"),
			emit: bam
		tuple val(metadata), path("${name}.${suffix}.tsv"), emit: group
		tuple val(metadata), path("${name}.${suffix}.tsv.gz"), emit: group_gz
		tuple val(metadata), path("${name}.${suffix}.log"), emit: log
		tuple val(metadata), path("Version"), emit: version

	script:

		name = metadata["name"]
		suffix = "umi_tools_group"

		"""
		umi_tools group \
			--extract-umi-method=read_id \
			--umi-separator=_ \
			--method=directional \
			--output-bam \
			--per-cell \
			--per-gene \
			--gene-tag="PB" \
			--group-out="${name}.${suffix}.tsv" \
			--stdin=$bam \
			--stdout="${name}.${suffix}.bam" \
			--log="${name}.${suffix}.log" \
			--umi-group-tag=BX \
			--edit-distance-threshold=3

		cat "${name}.${suffix}.tsv" | gzip -c > "${name}.${suffix}.tsv.gz"

		umi_tools --version > Version
		
		samtools index "${name}.${suffix}.bam"
		samtools --version >> Version
		"""
}

process collapse_barcodes {

	tag { "${name}" }

	label "python"

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/08_collapse_barcodes/${filename}" }

	input:
		tuple \
			val(metadata),
			path(tsv_gz),
			path(bam),
			path(bai),
			path(collapse_script),
			path(mip_lib),
			path(outliser_lib)

	output:
		tuple val(metadata), path("${name}.${suffix}.whitelist.tsv"), emit: whitelist
		tuple val(metadata), path("${name}.${suffix}.filtered_whitelist.tsv"), emit: filtered_whitelist
		tuple val(metadata), path("${name}.${suffix}.barcode_stats.tsv"), emit: barcode_stats
		tuple val(metadata), path("${name}.${suffix}.overlap_matrix.npz"), emit: overlap_matrix
		tuple val(metadata), path("${name}.${suffix}.plots.pdf"), emit: plots
		tuple val(metadata), path("${name}.${suffix}.log"), emit: log
		tuple val(metadata), path("${name}.${suffix}.stats.txt"), emit: stats
		tuple val(metadata), path("${name}.${suffix}.histogram.pdf"), emit: histo
		//tuple val(metadata), path("${name}.${suffix}.clustermap.pdf"), emit: clustermap

	script:

		name = metadata["name"]
		suffix = "collapse_barcodes"

		"""
		python3 $collapse_script \
			--groups=$tsv_gz \
			--whitelist="${name}.${suffix}.whitelist.tsv" \
			--filtered_whitelist="${name}.${suffix}.filtered_whitelist.tsv" \
			--barcode_stats="${name}.${suffix}.barcode_stats.tsv" \
			--overlap_mat="${name}.${suffix}.overlap_matrix.npz" \
			--plots="${name}.${suffix}.plots.pdf" \
			--log="${name}.${suffix}.log" \
			--stats="${name}.${suffix}.stats.txt"  \
			--thresh=0.005 \
			--histogram="${name}.${suffix}.histogram.pdf" \
			--clustermap="${name}.${suffix}.clustermap.pdf"
		"""
}

process duplication_rate {

	tag { "${name}" }

	label "python"

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/08_collapse_barcodes/${filename}" }

	input:
		tuple val(metadata), path(groups), path(whitelist), path(script)

	output:
		tuple val(metadata), path("${name}.${suffix}.groups.csv"), emit: groups
		tuple val(metadata), path("${name}.${suffix}.common_umis.csv"), emit: common_umis
		tuple val(metadata), path("${name}.${suffix}.duplicated_barcodes_count.csv"), emit: barcodes_csv
		tuple val(metadata), path("${name}.${suffix}.duplicated_barcodes_count.pdf"), emit: barcodes_pdf
		tuple val(metadata), path("${name}.${suffix}.duplicated_barcodes_count.png"), emit: barcodes_png
		tuple val(metadata), path("${name}.${suffix}.duplicated_reads_count.csv"), emit: reads_csv
		tuple val(metadata), path("${name}.${suffix}.duplicated_reads_count.pdf"), emit: reads_pdf
		tuple val(metadata), path("${name}.${suffix}.duplicated_reads_count.png"), emit: reads_png

	script:

		name = metadata["name"]
		suffix = "collapse_barcodes"

		"""
		python3 $script "${name}" $groups $whitelist "${suffix}"
		"""
}

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
			--per-contig \
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
		saveAs: { filename -> "${name}/06_umi_tools_count/${filename}" }

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

