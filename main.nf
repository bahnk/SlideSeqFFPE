#!/usr/bin/env nextflow

nextflow.enable.dsl=2

import java.nio.file.Paths

///////////////////////////////////////////////////////////////////////////////
//// METHODS //////////////////////////////////////////////////////////////////

/////////////////////////////////
def addValue(map, key, value) {//
/////////////////////////////////
	def new_map = map.clone()
	new_map.put(key, value)
	return new_map
}

/////////////////////////////
def removeKeys(map, keys) {//
/////////////////////////////
	def new_map = [:]
	map.each{
		if ( ! keys.contains(it.key) )
		{
			new_map.put(it.key, it.value)
		}
	}
	return new_map
}

///////////////////////////
def parseFileName(path) {//
///////////////////////////
	def fname = path.getName()
	def read_num = fname.replaceAll(".*_L\\d{3}_(R\\d)_\\d{3}.*", "\$1")
	def name = fname.replaceAll("(.*)_S\\d_L\\d{3}_.*", "\$1")
	return [ ["name":name] , read_num , path ]
}

///////////////////////////////////////////////////////////////////////////////
//// PROCESSES ////////////////////////////////////////////////////////////////

/////////////////
// demultiplexing

include { bcl2fastq } from "./modules/process/demultiplexing"
include { merge_lanes } from "./modules/process/demultiplexing"
/////////////////

//////////////
// subsampling

include { count_reads } from "./modules/process/subsampling"
include { subsample } from "./modules/process/subsampling"
//////////////

/////////////
// processing

include { filter_out_too_short_read1 } from "./modules/process/processing"
include { plot_filter_out_too_short_read1 } from "./modules/process/processing"
plot_long_enough_script = Channel.fromPath("$workflow.projectDir/bin/plot_long_enough.py")

include { extract_barcode_and_umi } from "./modules/process/processing"
include { filter_out_bad_up_primer } from "./modules/process/processing"

up_primer_script = Channel.fromPath("$workflow.projectDir/bin/up_primer.py")
plot_up_primer_script = Channel.fromPath("$workflow.projectDir/bin/plot_up_check.py")

include { extract_probe_sequence } from "./modules/process/processing"
extract_probe_script = Channel.fromPath("$workflow.projectDir/bin/probe_extraction.py")
plot_extract_probe_script = Channel.fromPath("$workflow.projectDir/bin/plot_extract_probe.py")
/////////////

////////////
// alignment

probes_fasta = Channel.fromPath(params.probes_fasta)
include { create_probe_index } from "./modules/process/align"
include { align_probe } from "./modules/process/align"

include { add_tags } from "./modules/process/align"
add_tags_script = Channel.fromPath("$workflow.projectDir/bin/add_tags.py")

include { check_mapping } from "./modules/process/align"
mapping_script = Channel.fromPath("$workflow.projectDir/bin/mapping.py")
plot_mapped_script = Channel.fromPath("$workflow.projectDir/bin/plot_read_mapped.py")
plot_hits_script = Channel.fromPath("$workflow.projectDir/bin/plot_read_hits.py")
plot_umis_script = Channel.fromPath("$workflow.projectDir/bin/plot_umis.py")
////////////

////////////////
// deduplication

include { umi_tools_group } from "./modules/process/deduplication"
include { umi_tools_group_barcodes } from "./modules/process/deduplication"

include { duplication_rate } from "./modules/process/deduplication"
duplication_rate_script = Channel.fromPath("$workflow.projectDir/bin/duplication_rate.py")

include { umi_tools_count } from "./modules/process/deduplication"
////////////////

//////////////////
// quality control

include { fastqc } from "./modules/process/quality_control"
include { multiqc } from "./modules/process/quality_control"
include { merge_plots } from "./modules/process/quality_control"

include { export_metrics } from "./modules/process/quality_control"
export_metrics_script = Channel.fromPath("$workflow.projectDir/bin/export_metrics.py")
//////////////////

///////////
// unmapped

template_fasta = Channel.fromPath(params.template_fasta)
include { create_template_index } from "./modules/process/unmapped"

include { align_unmapped } from "./modules/process/unmapped"

include { get_unmapped } from "./modules/process/unmapped"
include { get_unmapped_sequences } from "./modules/process/unmapped"

include { unmapped_read1 } from "./modules/process/unmapped"
unmapped_read1_script = Channel.fromPath("$workflow.projectDir/bin/unmapped_read1.py")
///////////

///////////////////////////////////////////////////////////////////////////////
//// SAMPLES //////////////////////////////////////////////////////////////////

Channel
	.fromPath(params.data_dir)
	.combine( Channel.fromPath(params.sample_sheet) )
	.set{ TO_DEMULTI }

///////////////////////////////////////////////////////////////////////////////
//// MAIN WORKFLOW ////////////////////////////////////////////////////////////

workflow {

	bcl2fastq(TO_DEMULTI)

	////////////////////////////////////////////////////////////////////////////

	bcl2fastq
		.out
		.fastqs
		.flatten()
		.map{parseFileName(it)}
		.groupTuple()
		.map{ [ it[0] , it[2].sort{ it.getName() } ] }
		.map{ [ it[0] , it[1][0] , it[1][1] ] }
		.filter{ it[0]["name"] != "Undetermined" }
		.set{ FASTQ }

	//// TODO
	//// merging the samples run on several lanes here
	//// the channel could be named SAMPLES

	fastqc(FASTQ)
	
	////////////////////////////////////////////////////////////////////////////

	count_reads(FASTQ)

	count_reads
		.out
		.map{ it[1].toInteger() }
		.min()
		.concat( Channel.value(params.reads_to_sample) )
		.min()
		.set{ MIN_READS }

	FASTQ
		.combine(MIN_READS)
		.map{ [ addValue(it[0], "min_reads", it[3]) , *it[1..2] ] }
		.map{[
			addValue(it[0], "name", it[0]["name"] + ".subsampled"),
			*it[1..2]
		]}
		.set{ TO_SUBSAMPLE }
	
	subsample(TO_SUBSAMPLE)

	FASTQ
		.concat(subsample.out)
		.set{ ALL_FASTQ }

	////////////////////////////////////////////////////////////////////////////

	filter_out_too_short_read1(ALL_FASTQ)
	plot_filter_out_too_short_read1(
		filter_out_too_short_read1
			.out
			.metrics
			.combine(plot_long_enough_script)
	)

	extract_barcode_and_umi(filter_out_too_short_read1.out.fastqs)
	filter_out_bad_up_primer(
		extract_barcode_and_umi
			.out
			.fastqs
			.combine(up_primer_script)
			.combine(plot_up_primer_script)
	)
	extract_probe_sequence(
		filter_out_bad_up_primer
			.out
			.pass
			.combine(extract_probe_script)
			.combine(plot_extract_probe_script)
	)

	////////////////////////////////////////////////////////////////////////////

	create_probe_index(probes_fasta)

	align_probe(
		extract_probe_sequence
			.out
			.fastq
			.combine( create_probe_index.out.index.map{[it]} )
	)

	check_mapping(
		align_probe
			.out
			.bam
			.combine(mapping_script)
			.combine(plot_mapped_script)
			.combine(plot_hits_script)
			.combine(plot_umis_script)
	)

	add_tags( align_probe.out.bam.combine(add_tags_script) )

	////////////////////////////////////////////////////////////////////////////

	umi_tools_group(add_tags.out.bam)
	umi_tools_group_barcodes(umi_tools_group.out.bam)
	umi_tools_count(umi_tools_group_barcodes.out.bam)

	umi_tools_group
		.out
		.group
		.concat(umi_tools_group_barcodes.out.group)
		.map{ [ it[0]["name"] , it ] }
		.groupTuple()
		.map{ [ *it[1][0] , it[1][1][1] ] }
		.set{ TO_DUP_RATE }

	duplication_rate( TO_DUP_RATE.combine(duplication_rate_script) )

	////////////////////////////////////////////////////////////////////////////

	plot_filter_out_too_short_read1.out.pdf
		.concat(filter_out_bad_up_primer.out.pdf)
		.concat(extract_probe_sequence.out.pdf)
		.concat(check_mapping.out.mapped_pdf)
		.concat(check_mapping.out.hits_pdf)
		.concat(check_mapping.out.reads_per_umi_pdf)
		.concat(check_mapping.out.umis_per_barcode_pdf)
		//.concat(check_mapping.out.mean_umis_per_barcode_pdf)
		//.concat(check_mapping.out.probes_per_umi_pdf)
		.concat(duplication_rate.out.reads_pdf)
		.concat(duplication_rate.out.umis_pdf)
		.map{ [ it[0]["name"] , it[1] ] }
		.groupTuple()
		.set{PDFS}

	merge_plots(PDFS)

	filter_out_too_short_read1
		.out
		.metrics
		.concat(
			extract_barcode_and_umi.out.metrics,
			filter_out_bad_up_primer.out.metrics,
			extract_probe_sequence.out.metrics,
			check_mapping.out.mapped,
			duplication_rate.out.reads_csv,
			duplication_rate.out.umis_csv
		)
		.map{it[1]}
		.collect()
		.map{[it]}
		.set{ TO_EXPORT }
	
	export_metrics( TO_EXPORT.combine(export_metrics_script) )

	////////////////////////////////////////////////////////////////////////////

	create_template_index(template_fasta)

	get_unmapped(
		align_probe
			.out
			.bam
			.filter{ ! it[0]["name"].endsWith(".subsampled") }
	)

	filter_out_bad_up_primer
		.out
		.pass
		.filter{ ! it[0]["name"].endsWith(".subsampled") }
		.concat(get_unmapped.out)
		.map{ [ it[0]["name"] , *it ] }
		.groupTuple()
		.map{ [ it[1][0] , *it[2] ] }
		.set{ TO_GET_UNMAPPED_SEQ }

	get_unmapped_sequences(TO_GET_UNMAPPED_SEQ)

	align_unmapped(
		get_unmapped_sequences
			.out
			.fastq
			.combine( create_template_index.out.index.map{[it]} )
	)

	FASTQ 
		.concat(get_unmapped.out)
		.map{ [ it[0]["name"] , it ] }
		.groupTuple()
		.map{ [ it[1][0][0] , *it[1][0][1..2] , it[1][1][1] ] }
		.set{ TO_UNMAPPED_READ1 }
	
	unmapped_read1( TO_UNMAPPED_READ1.combine(unmapped_read1_script) )

	////////////////////////////////////////////////////////////////////////////

	//bcl2fastq.out.stats
	//bcl2fastq.out.reports
	//fastqc.out.html
	//fastqc.out.zip
	//filter_out_too_short_read1.out.log
	//extract_barcode_and_umi.out.log
	//// TODO filter_out_bad_up_primer
	//// TODO extract_probe_sequence
	//// TODO create_probe_index
	//align_probe.out.stats
	//umi_tools_deduplicate.out.log
	//umi_tools_deduplicate.out.stats
	//umi_tools_count.out.log

	bcl2fastq
		.out
		.stats
		.concat(
			bcl2fastq.out.reports,
			fastqc.out.html.map{it[1]},
			fastqc.out.zip.map{it[1]},
			filter_out_too_short_read1.out.log.map{it[1]},
			extract_barcode_and_umi.out.log.map{it[1]},
			align_probe.out.log.map{it[1]},
			align_probe.out.stats.map{it[1]},
			umi_tools_group.out.log.map{it[1]},
			umi_tools_group_barcodes.out.log.map{it[1]},
			//umi_tools_deduplicate.out.log.map{it[1]},
			//umi_tools_deduplicate.out.stats.map{it[1]},
			umi_tools_count.out.log.map{it[1]}
		)
		.collect()
		.set{ TO_MULTIQC }

	multiqc(TO_MULTIQC)
}

