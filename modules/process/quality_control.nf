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

