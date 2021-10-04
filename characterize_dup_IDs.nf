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

process find_duplicated_entries {
    publishDir "${params.intermediates}/${id}", mode: 'rellink', overwrite: true
    input:
      tuple val(id), path(filein)
    output:
      tuple val(id), path('duplicate_ids')
    script:
      """
      find_duplicate_ids.sh ${filein} > "duplicate_ids"
      """
}

process extract_from_vcf {
    publishDir "${params.intermediates}/${id}", mode: 'rellink', overwrite: true
    input:
      tuple val(id), path(vcfin), path(filein)
    output:
      tuple val(id), path('extracted.vcf.gz'), path('extracted.vcf.gz.tbi')
    script:
      """
      extract_from_vcf.sh ${filein} ${vcfin} "extracted.vcf.gz"
      """
}

process calc_af_from_genotype {
    publishDir "${params.intermediates}/${id}", mode: 'rellink', overwrite: true
    input:
      tuple val(id), path("extracted.vcf.gz"), path("extracted.vcf.gz.tbi")
    output:
      tuple val(id), path('allele_freqs')
    script:
      """
      calc_af_from_genotype.sh extracted.vcf.gz > "allele_freqs"
      """
}

process split_based_on_id {
    publishDir "${params.intermediates}/${id}", mode: 'rellink', overwrite: true
    input:
      tuple val(id), path(vcfin)
    output:
      tuple val(id), path('extracted.vcf.gz')
    script:
      """
      split_based_on_id.sh ${vcfin} > "split.vcf.gz"
      """
}

workflow {
  
  // Make channel
  channel.fromPath("${params.input}")
    .map { file -> tuple(file.baseName - ~/\.gz/, file) }
    .transpose()
    .set { vcf_filename_tracker_added }
  

  extract_ids_from_vcf_and_create_index(vcf_filename_tracker_added)
  find_duplicated_entries(extract_ids_from_vcf_and_create_index.out)
  vcf_filename_tracker_added
    .join(find_duplicated_entries.out, by:0)
    .set { to_extract_vcf }
  extract_from_vcf(to_extract_vcf)

  calc_af_from_genotype(extract_from_vcf.out)

}


