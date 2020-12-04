nextflow.enable.dsl=2

params.bam = "*.{bam,bai}"
params.outdir = "results"
params.reference_file_path = "/exports/igmm/eddie/tomlinson-CRC-promethion/analysis/clair/hg38.fa"
params.vepdir ="/exports/igmm/eddie/tomlinson-CRC-promethion/analysis/vep"
params.model = "/exports/igmm/eddie/tomlinson-CRC-promethion/analysis/clair/ont/model"
params.out_prefix = "$baseDir/claircalls/var"
params.threshold = 0.2
params.clair="/exports/igmm/eddie/tomlinson-CRC-promethion/analysis/clair/clair-env/bin/clair.py"

bam_ch = Channel
            .fromFilePairs(params.bam) {file -> file.name.replaceAll(/.bam|.bai$/,'')}




log.info """\
         CLAIR - N F   P I P E L I N E
         ===================================
         bam                       : ${params.bam}
         outdir                    : ${params.outdir}
         reference_file_path       : ${params.reference_file_path}
         """
         .stripIndent()

include {
  clair;
  concat;
  } from './modules/clair2.nf'


Channel
  .fromFilePairs(params.bam) { file -> file.name.replaceAll(/.bam|.bai$/,'') }
  .into{bam_ch;bam_ch2}


workflow {

  clair(bam_ch,params.reference_file_path,params.clair,params.model,params.threshold)

  cmd=clair.out.splitText()

  run_clair(cmd, bam_ch2,params.reference_file_path,params.clair,params.model,params.threshold)

  combinedvcf=run_clair.out.groupTuple()

  concat(combinedvcf)
}
