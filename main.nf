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

/////////////
// processing

include { filter_out_too_short_read1 } from "./modules/process/processing"
include { plot_filter_out_too_short_read1 } from "./modules/process/processing"
plot_long_enough_script = Channel.fromPath("$workflow.projectDir/bin/plot_long_enough.py")

include { extract_barcode_and_umi } from "./modules/process/processing"
include { filter_out_bad_up_primer } from "./modules/process/processing"

up_primer_script = Channel.fromPath("$workflow.projectDir/bin/up_primer.py")
include { extract_probe_sequence } from "./modules/process/processing"
plot_up_primer_script = Channel.fromPath("$workflow.projectDir/bin/plot_up_check.py")
/////////////

////////////
// alignment

probes_fasta = Channel.fromPath(params.probes_fasta)
include { create_probe_index } from "./modules/process/align"
include { align_probe } from "./modules/process/align"

include { add_probe_tag } from "./modules/process/align"
add_probe_tag_script = Channel.fromPath("$workflow.projectDir/bin/add_probe_tag.py")

include { check_mapping } from "./modules/process/align"
mapping_script = Channel.fromPath("$workflow.projectDir/bin/mapping.py")
plot_mapped_script = Channel.fromPath("$workflow.projectDir/bin/plot_read_mapped.py")
plot_hits_script = Channel.fromPath("$workflow.projectDir/bin/plot_read_hits.py")
plot_umis_script = Channel.fromPath("$workflow.projectDir/bin/plot_umis.py")
////////////

////////////////
// deduplication

include { umi_tools_group } from "./modules/process/deduplication"

include { collapse_barcodes } from "./modules/process/deduplication"
Channel
	.fromPath([
		"$workflow.projectDir/assets/hypr-seq/collapse_barcodes.py",
		"$workflow.projectDir/assets/hypr-seq/mip_tools.py",
		"$workflow.projectDir/assets/hypr-seq/outlier_aware_hist.py"
	])
	.collect()
	.set{ collapse_script }

include { duplication_rate } from "./modules/process/deduplication"
duplication_rate_script = Channel.fromPath("$workflow.projectDir/bin/duplication_rate.py")

include { umi_tools_deduplicate } from "./modules/process/deduplication"
include { umi_tools_count } from "./modules/process/deduplication"
////////////////

//////////////
// subsampling

include { subsample } from "./modules/process/subsampling"
subsample_script = Channel.fromPath("$workflow.projectDir/bin/subsample.py")
//////////////

//////////////////
// quality control

include { fastqc } from "./modules/process/quality_control"
include { multiqc } from "./modules/process/quality_control"
include { merge_plots } from "./modules/process/quality_control"
//////////////////

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

	fastqc(FASTQ)

	// TODO
	// merging the samples run on several lanes here
	// the channel could be named SAMPLES

	////////////////////////////////////////////////////////////////////////////

	filter_out_too_short_read1(FASTQ)
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
	extract_probe_sequence(filter_out_bad_up_primer.out.pass)

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

	add_probe_tag( align_probe.out.bam.combine(add_probe_tag_script) )

	////////////////////////////////////////////////////////////////////////////

	umi_tools_group(add_probe_tag.out.bam)

	umi_tools_group
		.out
		.group
		.concat(umi_tools_group.out.bam)
		.map{ [ it[0]["name"] , it ] }
		.groupTuple()
		.map{ [ *it[1][0] , *it[1][1][1..2] ] }
		.set{ TO_SUBSAMPLE }

	subsample( TO_SUBSAMPLE.combine(subsample_script) )

	subsample
		.out
		.group_gz
		.concat(subsample.out.bam)
		.map{ [ it[0]["name"] , it ] }
		.groupTuple()
		.map{ [ *it[1][0] , *it[1][1][1..2] ] }
		.set{ TO_COLLAPSE }

	collapse_barcodes( TO_COLLAPSE.combine(collapse_script) )

	subsample
		.out
		.group
		.concat(collapse_barcodes.out.whitelist)
		.map{ [ it[0]["name"] , it ] }
		.groupTuple()
		.map{ [ *it[1][0] , it[1][1][1] ] }
		.set{TO_DUP_RATE}

	duplication_rate( TO_DUP_RATE.combine(duplication_rate_script) )


	//umi_tools_deduplicate(align_probe.out.bam)
	//umi_tools_count(umi_tools_deduplicate.out.bam)
	//umi_tools_count(align_probe.out.bam)

	////////////////////////////////////////////////////////////////////////////

	//plot_filter_out_too_short_read1.out.pdf
	//	.concat(filter_out_bad_up_primer.out.pdf)
	//	.concat(check_mapping.out.mapped_pdf)
	//	.concat(check_mapping.out.hits_pdf)
	//	.concat(check_mapping.out.reads_per_umi_pdf)
	//	.concat(check_mapping.out.umis_per_barcode_pdf)
	//	.concat(check_mapping.out.mean_umis_per_barcode_pdf)
	//	.concat(check_mapping.out.probes_per_umi_pdf)
	//	.map{ [ it[0]["name"] , it[1] ] }
	//	.groupTuple()
	//	.set{PDFS}

	//merge_plots(PDFS)

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

	//bcl2fastq
	//	.out
	//	.stats
	//	.concat(
	//		bcl2fastq.out.reports,
	//		fastqc.out.html.map{it[1]},
	//		fastqc.out.zip.map{it[1]},
	//		filter_out_too_short_read1.out.log.map{it[1]},
	//		extract_barcode_and_umi.out.log.map{it[1]},
	//		align_probe.out.log.map{it[1]},
	//		align_probe.out.stats.map{it[1]},
	//		//umi_tools_deduplicate.out.log.map{it[1]},
	//		//umi_tools_deduplicate.out.stats.map{it[1]},
	//		umi_tools_count.out.log.map{it[1]}
	//	)
	//	.collect()
	//	.set{ TO_MULTIQC }

	//multiqc(TO_MULTIQC)
}

