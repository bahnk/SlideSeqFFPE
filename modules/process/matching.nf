import java.nio.file.Paths

process barcode_matching {

	tag { "${name}" }

	label "gpu"

	publishDir Paths.get( params.output_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename -> "${name}/10_barcode_matching/${filename}" }

	input:
		tuple val(metadata), path(counts), path(spatial), path(script)

	output:
		tuple val(metadata), path("${basename}.hamming.csv"), emit: hamming
		tuple val(metadata), path("${basename}.dge.csv"), emit: dge
		tuple val(metadata), path("${basename}.umis.pdf"), emit: umis_pdf
		tuple val(metadata), path("${basename}.umis.png"), emit: umis_png

	script:

		name = metadata["name"]
		basename = "${name}.barcode_matching"
		hamming = "${basename}.hamming.csv"

		"""
		cut -f 2 $counts | sed '1d' | sort | uniq > read_barcodes.txt
		cut -f 1 $spatial | sort | uniq > puck_barcodes.txt

		hamming read_barcodes.txt puck_barcodes.txt "${hamming}"

		python3 $script \
			$counts \
			$spatial \
			"${hamming}" \
			$params.maximum_errors_bead_barcode \
			"${basename}"
		"""
}
