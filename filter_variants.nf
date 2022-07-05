#!/usr/bin/env nextflow
nextflow.enable.dsl = 1

params.samples_file=''
params.genotype_file=''

// Read samples file
Channel
	.fromPath(params.samples_file)
	.splitCsv(header:true, sep:'\t')
	.map{ row -> tuple( row.indiv_id, row.hotspots_file, row.filtered_sites_file ) }
	.set{ INDIV_CELL_TYPE }

process filter_variants {
	tag "${outname}"

	publishDir "${params.outdir}/bed_files", mode: 'symlink'

	input:
	tuple val(indiv_id), val(hotspots_file), val(outname) from INDIV_CELL_TYPE
	
	file genotype_file from file(params.genotype_file)
	file '*' from file("${params.genotype_file}.csi")

	output:
	tuple file(outname), file("${outname}.tbi")

	script:
	"""
	# TODO
	#add 

	bcftools query \
		-s ${indiv_id} \
		-i'GT="alt"' \
		-f'%CHROM\\t%POS0\\t%POS\\t%ID\\t%REF\\t%ALT\\t%INFO/MAF\\t[%GT\\t%GQ\\t%DP\\t%AD{0}\\t%AD{1}]\\n' \
		${genotype_file} \
	| awk -v OFS="\\t" \
		-v min_GQ=${params.min_GQ} -v min_AD=${params.min_AD} -v min_DP=${params.min_DP}\
		'\$9<min_GQ { next; } \$10<min_DP { next; }\
			(\$8=="0/1" || \$8=="1/0" || \$8=="0|1" || \$8=="1|0") && (\$11<min_AD || \$12<min_AD) { \
				next; \
			} \
			{ print; }' \
	| sort-bed - \
	| grep -v chrX | grep -v chrY | grep -v chrM | grep -v _random | grep -v _alt | grep -v chrUn \
	| bedops -e 1 - ${hotspots_file} \
	| bgzip -c > ${outname}

	tabix -f -p bed ${outname}
	"""
}

