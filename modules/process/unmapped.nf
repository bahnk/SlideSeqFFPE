import java.nio.file.Paths

process create_template_index {

	label "sequencing"
	cpus 2

	publishDir Paths.get( params.output_dir , "indexes", "template_index" ),
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

process get_unmapped {

	tag { "${name}" }
	
	label "sequencing"

	publishDir Paths.get( params.out_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/09_unmapped/${filename}" }

	input:
		tuple val(metadata), path(bam), path(bai)

	output:
		tuple val(metadata), file("${name}.unmapped.txt")

	script:		

		name = metadata["name"]
		
		"""
		samtools view -f 4 $bam \
			| awk '{ print \$1 }' \
			| sort \
			| uniq \
			> "${name}.unmapped.txt"
		"""
}

process get_unmapped_sequences {

	tag { "${name}" }
	
	label "sequencing"

	publishDir Paths.get( params.out_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/09_unmapped/${filename}" }

	input:
		tuple val(metadata), path(fastq), path(reads)

	output:
		tuple val(metadata), file("${name}.unmapped.fastq.gz"), emit: fastq
		tuple val(metadata), file("Version"), emit: version

	script:		

		name = metadata["name"]
		
		"""
		/usr/share/bbmap/filterbyname.sh \
			in=$fastq \
			out="${name}.unmapped.fastq" \
			include=true \
			names=$reads

		cat "${name}.unmapped.fastq" | gzip -c > "${name}.unmapped.fastq.gz"

		dpkg -l bbmap > Version
		"""
}

process align_unmapped {

	tag { "${name}" }

	label "sequencing"
	cpus 12

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/09_unmapped/${filename}" }

	input:
		tuple val(metadata), path(fastq), path(index)

	output:
		tuple val(metadata), path("${name}.${suffix}.bam"), path("${name}.${suffix}.bam.bai"), emit: bam
		tuple val(metadata), path("${name}.${suffix}.log"), emit: log
		tuple val(metadata), path("${name}.${suffix}.samtools_stats.txt"), emit: stats
		tuple val(metadata), path("Version"), emit: version

	script:

		name = metadata["name"]
		suffix = "align_unmapped"

		"""
		bowtie2 \
			-x index \
			--threads $task.cpus \
			-S "${name}.${suffix}.sam" \
			--local \
			$fastq \
			2> "${name}.${suffix}.log"
		bowtie2 --version > Version

		samtools sort "${name}.${suffix}.sam" > "${name}.${suffix}.bam"
		samtools index "${name}.${suffix}.bam"
		samtools stats "${name}.${suffix}.bam" > "${name}.${suffix}.samtools_stats.txt"
		samtools --version >> Version
		"""
}

process unmapped_read1 {

	tag { "${name}" }

	label "python"
	cpus 2

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/09_unmapped/${filename}" }

	input:
		tuple val(metadata), path(fastq1), path(fastq2), path(reads), path(script)

	output:
		tuple val(metadata), path("${name}.${suffix}.reads.csv"), emit: reads
		tuple val(metadata), path("${name}.${suffix}.counts.csv"), emit: counts

	script:

		name = metadata["name"]
		suffix = "unmapped_read1"

		"""
		python3 $script "${name}.${suffix}" $fastq1 $fastq2 $reads
		"""
}

