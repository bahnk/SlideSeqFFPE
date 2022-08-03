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

process check_mapping {

	tag { "${name}" }

	label "python"

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/05_align_probe/${filename}" }

	input:
		tuple \
			val(metadata),
			path(bam),
			path(bai),
			path(script),
			path(plot_mapped_script),
			path(plot_hits_script),
			path(plot_umis_script)

	output:
		tuple val(metadata), path("${name}.mapped.csv"), emit: mapped
		tuple val(metadata), path("${name}.mapped.pdf"), emit: mapped_pdf
		tuple val(metadata), path("${name}.mapped.png"), emit: mapped_png
		tuple val(metadata), path("${name}.hits.csv"), emit: hits
		tuple val(metadata), path("${name}.hits.pdf"), emit: hits_pdf
		tuple val(metadata), path("${name}.hits.png"), emit: hits_png
		tuple val(metadata), path("${name}.reads_per_umi.pdf"), emit: reads_per_umi_pdf
		tuple val(metadata), path("${name}.reads_per_umi.png"), emit: reads_per_umi_png
		tuple val(metadata), path("${name}.umis_per_barcode.pdf"), emit: umis_per_barcode_pdf
		tuple val(metadata), path("${name}.umis_per_barcode.png"), emit: umis_per_barcode_png
		tuple val(metadata), path("${name}.mean_umis_per_barcode.pdf"), emit: mean_umis_per_barcode_pdf
		tuple val(metadata), path("${name}.mean_umis_per_barcode.png"), emit: mean_umis_per_barcode_png
		tuple val(metadata), path("${name}.probes_per_umi.pdf"), emit: probes_per_umi_pdf
		tuple val(metadata), path("${name}.probes_per_umi.png"), emit: probes_per_umi_png

	script:

		name = metadata["name"]

		"""
		python3 $script $bam "${name}"
		python3 $plot_mapped_script "${name}.mapped.csv" "${name}"
		python3 $plot_hits_script "${name}.hits.csv" "${name}"
		python3 $plot_umis_script $bam "${name}"
		"""
}

