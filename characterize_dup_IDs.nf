nextflow.enable.dsl=2

process extract_ids_from_vcf_and_create_index {
    publishDir "${params.intermediates}/${id}", mode: 'rellink', overwrite: true
    input:
      tuple val(id), path(vcfin)
    output:
      tuple val(id), path('extract_ids_from_vcf_and_create_index')
    script:
      """
      extract_ids_from_vcf_and_create_index.sh ${vcfin} > "extract_ids_from_vcf_and_create_index"
      """
}

workflow {
  
  // Make channel
  channel.fromPath("${params.input}")
    .map { file -> tuple(file.baseName - ~/\.gz/, file) }
    .transpose()
    .set { vcf_filename_tracker_added }
  

  extract_ids_from_vcf_and_create_index(vcf_filename_tracker_added)

}

