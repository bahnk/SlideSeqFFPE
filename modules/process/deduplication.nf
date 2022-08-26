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
		tuple val(metadata), path("${name}.${suffix}.mean_umis_per_barcode.csv"), emit: umis_csv
		tuple val(metadata), path("${name}.${suffix}.mean_umis_per_barcode.pdf"), emit: umis_pdf
		tuple val(metadata), path("${name}.${suffix}.mean_umis_per_barcode.png"), emit: umis_png

	script:

		name = metadata["name"]
		suffix = "deduplication"

		"""
		python3 $script "${name}" $umi_groups $barcode_groups "${suffix}"
		"""
}

