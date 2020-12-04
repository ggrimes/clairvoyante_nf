/*
Call variants in parrallel using https://github.com/HKU-BAL/Clair
*/
process clair {
    tag "$bam"
    label 'high_memory'
    conda '/exports/igmm/eddie/tomlinson-CRC-promethion/analysis/clair/clair-env'


    input:
    tuple(val(sampleName), file(bam))
    val(reference_fa)
    val(clair)
    val(model)
    val(threshold)

    output:
    path("command.sh")

    script:
    """
    # create command.sh for run jobs in parallel
    clair.py callVarBamParallel \
    --chkpnt_fn "${model}" \
    --ref_fn "${reference_fa}" \
    --minCoverage "4" \
    --bam_fn "${sampleName}.bam" \
    --threshold ${threshold} \
    --sampleName "${sampleName}" \
    --threads ${${task.cpus}} \
    --includingAllContigs \
    --output_prefix ${sampleName} > commands.sh
    grep python commands.sh > command.sh
    """
}

process run_clair {
 conda '/exports/igmm/eddie/tomlinson-CRC-promethion/analysis/clair/clair-env'

 input:
 val(cmd)
 tuple(val(sampleName), file(bam))
 val(reference_fa)
 val(clair)
 val(model)
 val(threshold)

 output:
 tuple(val("${sampleName}"),path("${sampleName}*.vcf"))

 script:
 """
 # disable GPU if you have one installed
 export CUDA_VISIBLE_DEVICES=""
  ${cmd.trim()}
 """

}

process concat {
  tag "concat"
  label 'high_memory'
  publishDir "results/claircalls", mode: 'copy'
  conda '/exports/igmm/eddie/tomlinson-CRC-promethion/analysis/clair/clair-env'
  cpus 16

  input:
  tuple(val(sampleName), path(vcfs))

  output:
  path("${sampleName}_snp_and_indel.vcf.gz*")

  script:
  """
    # concatenate vcf files and sort the variants called
    vcfcat ${vcfs} | \
    bcftools sort -m 8G --temp-dir . | \
    bgziptabix ${sampleName}_snp_and_indel.vcf.gz
  """
}
