import java.nio.file.Paths

process subsample {

	tag { "${name}" }

	label "python"

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/07_barcode_subsampling/${filename}" }

	input:
		tuple val(metadata), path(tsv), path(bam), path(bai), path(script)

	output:
		tuple \
			val(metadata),
			path("${name}.${suffix}.bam"),
			path("${name}.${suffix}.bam.bai"),
			emit: bam
		tuple val(metadata), path("${name}.${suffix}.tsv"), emit: group
		tuple val(metadata), path("${name}.${suffix}.tsv.gz"), emit: group_gz

	script:

		name = metadata["name"]
		suffix = "group_subsampled"

		"""
		python3 $script "${name}" $tsv $bam 5000 "${suffix}"
		cat "${name}.${suffix}.tsv" | gzip -c > "${name}.${suffix}.tsv.gz"
		samtools index "${name}.${suffix}.bam"
		"""
}

