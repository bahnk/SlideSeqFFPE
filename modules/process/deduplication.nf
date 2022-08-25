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
			--method=directional \
			--extract-umi-method=tag \
			--umi-tag=UM \
			--umi-group-tag=UX \
			--per-cell \
			--cell-tag=BC \
			--per-gene \
			--gene-tag=PB \
			--stdin=$bam \
			--output-bam \
			--stdout="${name}.${suffix}.bam" \
			--group-out="${name}.${suffix}.tsv" \
			--log="${name}.${suffix}.log" \
			--edit-distance-threshold=1

		cat "${name}.${suffix}.tsv" | gzip -c > "${name}.${suffix}.tsv.gz"

		umi_tools --version > Version
		
		samtools index "${name}.${suffix}.bam"
		samtools --version >> Version
		"""
}

process umi_tools_group_barcodes {

	tag { "${name}" }

	label "sequencing"

	time "03:00:00"
	//memory "300G"

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/07_umi_tools_group_barcodes/${filename}" }

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
		suffix = "umi_tools_group_barcodes"

		"""
		umi_tools group \
			--extract-umi-method=tag \
			--method=directional \
			--umi-tag=BC \
			--umi-group-tag=BX \
			--per-cell \
			--cell-tag=UX \
			--per-gene \
			--gene-tag=PB \
			--stdin=$bam \
			--output-bam \
			--stdout="${name}.${suffix}.bam" \
			--group-out="${name}.${suffix}.tsv" \
			--log="${name}.${suffix}.log" \
			--edit-distance-threshold=1

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
		saveAs: { filename -> "${name}/08_umi_tools_count/${filename}" }

	input:
		tuple val(metadata), path(umi_groups), path(barcode_groups), path(script)

	output:
		tuple val(metadata), path("${name}.${suffix}.duplicated_reads_count.csv"), emit: reads_csv
		tuple val(metadata), path("${name}.${suffix}.duplicated_reads_count.pdf"), emit: reads_pdf
		tuple val(metadata), path("${name}.${suffix}.duplicated_reads_count.png"), emit: reads_png
		tuple val(metadata), path("${name}.${suffix}.corrected_barcodes.csv"), emit: barcodes
		tuple val(metadata), path("${name}.${suffix}.mean_umis_per_barcode.pdf"), emit: umis_pdf
		tuple val(metadata), path("${name}.${suffix}.mean_umis_per_barcode.png"), emit: umis_png

	script:

		name = metadata["name"]
		suffix = "deduplication"

		"""
		python3 $script "${name}" $umi_groups $barcode_groups "${suffix}"
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
		saveAs: { filename -> "${name}/08_umi_tools_count/${filename}" }

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
			--extract-umi-method=tag \
			--method=directional \
			--umi-tag=UX \
			--per-cell \
			--cell-tag=BX \
			--per-gene \
			--gene-tag=PB \
			--stdin=$bam \
			--stdout="${name}.count.tsv" \
			--log="${name}.count.log"

		umi_tools --version > Version
		"""
}

