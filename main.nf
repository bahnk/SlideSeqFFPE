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
include { extract_barcode_and_umi } from "./modules/process/processing"
include { filter_out_bad_up_primer } from "./modules/process/processing"

up_primer_script = Channel.fromPath("bin/up_primer.py")
include { extract_probe_sequence } from "./modules/process/processing"
/////////////

////////////
// alignment

probes_fasta = Channel.fromPath("assets/probes.fasta")
include { create_probe_index } from "./modules/process/align"
include { align_probe } from "./modules/process/align"
////////////

////////////////
// deduplication

include { umi_tools_deduplicate } from "./modules/process/deduplication"
include { umi_tools_count } from "./modules/process/deduplication"
////////////////

//////////////////
// quality control

include { fastqc } from "./modules/process/quality_control"
include { multiqc } from "./modules/process/quality_control"
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

	///////////////////////////////////////////////////////////////////////////

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

	///////////////////////////////////////////////////////////////////////////

	filter_out_too_short_read1(FASTQ)
	extract_barcode_and_umi(filter_out_too_short_read1.out.fastqs)
	filter_out_bad_up_primer(
		extract_barcode_and_umi
			.out
			.fastqs
			.combine(up_primer_script)
	)
	extract_probe_sequence(filter_out_bad_up_primer.out.pass)

	///////////////////////////////////////////////////////////////////////////

	create_probe_index(probes_fasta)
	align_probe(
		extract_probe_sequence
			.out
			.fastq
			.combine( create_probe_index.out.index.map{[it]} )
	)

	///////////////////////////////////////////////////////////////////////////

	umi_tools_deduplicate(align_probe.out.bam)
	umi_tools_count(umi_tools_deduplicate.out.bam)

	///////////////////////////////////////////////////////////////////////////
	
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
			umi_tools_deduplicate.out.log.map{it[1]},
			umi_tools_deduplicate.out.stats.map{it[1]},
			umi_tools_count.out.log.map{it[1]}
		)
		.collect()
		.set{ TO_MULTIQC }

	multiqc(TO_MULTIQC)
}

