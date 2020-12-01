/*
Call variants in parrallel using https://github.com/HKU-BAL/Clair
*/
process clair {
    tag "$bam"
    label 'high_memory'
    publishDir "results/claircalls", mode: 'copy'
    conda '/exports/igmm/eddie/tomlinson-CRC-promethion/analysis/clair/clair-env'

    cpus 16

    input:
    tuple(val(sampleName), file(bam))
    path(reference_fa)
    path(clair)
    val(model)
    val(threshold)

    output:
    file("${sampleName}_snp_and_indel.vcf.gz*")

    script:
    """
    # create command.sh for run jobs in parallel
    python clair.py callVarBamParallel \
    --chkpnt_fn "${model}" \
    --ref_fn "${reference_fa}" \
    --minCoverage "4" \
    --bam_fn "${sampleName}.bam" \
    --threshold ${threshold} \
    --sampleName "${sampleName}" \
    --output_prefix call/var > command.sh

    # disable GPU if you have one installed
    export CUDA_VISIBLE_DEVICES=""

    # run Clair with 4 concurrencies
    cat command.sh | parallel -j${task.cpus}


    # concatenate vcf files and sort the variants called
    vcfcat call/var/*.vcf | \
    bcftools sort -m 2G | \
    bgziptabix ${sampleName}_snp_and_indel.vcf.gz
  """
}
