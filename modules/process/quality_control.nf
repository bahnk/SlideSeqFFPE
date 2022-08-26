import java.nio.file.Paths

process fastqc {

	tag { "${name}" }
	
	label "sequencing"

	publishDir Paths.get( params.out_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/00_fastqc/${filename}" }

	input:
		tuple val(metadata), path(fastq1), path(fastq2)

	output:
		tuple val(metadata), file("*_fastqc.html"), emit: html
		tuple val(metadata), file("*_fastqc.zip"), emit: zip
		tuple val(metadata), file("Version"), emit: version

	script:		

		name = metadata["name"]
		
		"""
		fastqc $fastq1 $fastq2
		fastqc --version > Version
		"""
}

process multiqc {

	label "sequencing"

	publishDir Paths.get( params.out_dir ),
		mode: "copy",
		overwrite: "true"

	input:
		path files

	output:
		path "multiqc_report.html", emit: html
		path "multiqc_data", emit: data

	script:		
		"""
		multiqc .
		"""
}

process merge_plots {

	tag { "${name}" }

	label "python"

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/${filename}" }

	input:
		tuple val(name), path(pdfs)

	output:
		file "${name}.pdf"

	script:
		"""
		pdfunite $pdfs "${name}.pdf"
		"""
}

process export_metrics {

	tag { "${name}" }

	label "python"

	publishDir Paths.get( params.output_dir ), mode: "copy", overwrite: "true"

	input:
		tuple path(csvs), path(script)

	output:
		file "${name}.read_counts.csv"
		file "${name}.read_percent.csv"
		file "${name}.umis_per_barcode.csv"
		file "${name}.duplicates_percent.csv"

	script:

		name = "metrics"

		"""
		python3 $script "${name}" "."
		"""
}

