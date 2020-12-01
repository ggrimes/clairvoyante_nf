nextflow.enable.dsl=2

params.bam = "*.{bam,bai}"
params.outdir = "results"
params.reference = "ref"

log.info """\
         CLAIR - N F   P I P E L I N E
         ===================================
         bam           : ${params.bam}
         outdir          : ${params.outdir}
         reference       : ${params.reference}
         """
         .stripIndent()

include {
  clairvoyante;
  } from './modules/clair.nf'


Channel
  .fromFilePairs(params.bam) { file -> file.name.replaceAll(/.bam|.bai$/,'') }
  .set{bam_ch}

Channel
  .fromPath(params.reference)
  .set{ref_ch}


workflow {
  clair(bam_ch,ref_ch)
}
