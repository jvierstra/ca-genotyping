#!/usr/bin/env nextflow
params.genotype_file=''

process clusterIndivs {

    publishDir "${params.outdir}/clustering"

    input:
        tuple path(vcf_file)
    output:
        tuple path('metadata.clustered.tsv'), path('clustering.png')
    script:
    """
    plink2 --allow-extra-chr \
    --make-king square \
    --out snps.clustering \
    --vcf ${vcf_file}

    python3 $baseDir/bin/cluster_king.py --matrix snps.clustering.king \
    --matrix-ids snps.clustering.king.id \
    --meta-file ${params.samples_file} \
    --outpath ./
    """
}

workflow {
    vcf_and_index = Channel.value(params.genotype_file)
    clusterIndivs(vcf_and_index)

}