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

process find_duplicated_ids {
    publishDir "${params.intermediates}/${id}", mode: 'rellink', overwrite: true
    input:
      tuple val(id), path(filein)
    output:
      tuple val(id), path('duplicate_ids_to_replace')
    script:
      """
      find_duplicated_ids.sh ${filein} > "duplicate_ids_to_replace"
      """
}

process extract_from_vcf {
    publishDir "${params.intermediates}/${id}", mode: 'rellink', overwrite: true
    input:
      tuple val(id), path(vcfin), path(filein)
    output:
      tuple val(id), path('extracted2.vcf.gz'), path('extracted2.vcf.gz.tbi')
    script:
      """
      extract_from_vcf.sh ${filein} ${vcfin} "extracted2.vcf.gz"
      """
}

process change_extracted_vcf {
    publishDir "${params.intermediates}/${id}", mode: 'rellink', overwrite: true
    input:
      tuple val(id), path("extracted2.vcf.gz"), path("extracted2.vcf.gz.tbi")
    output:
      tuple val(id), path('extracted2_changed.vcf.gz'), path('extracted2_changed.vcf.gz.tbi')
    script:
      """
      # print map to rsid for the ones changed
      change_extracted_vcf.sh "extracted2.vcf.gz" extracted2_changed.vcf.gz
      """
}

process insert_the_new_dup_names {
    publishDir "${params.outdir}/updated_vcf", mode: 'copy', overwrite: true
    input:
      tuple val(id), path("vcfin.gz"), path("vcfin.gz.tbi"), path("extracted2_changed.vcf.gz"), path("extracted2_changed.vcf.gz.tbi")
    output:
      tuple val(id), path("${id}.gz"), path("${id}.gz.tbi")
    script:
      """
      join_input_and_map.sh vcfin.gz extracted2_changed.vcf.gz ${id}.gz
      """
}

workflow {
  
  // Make channel
  channel.fromPath("${params.input}")
    .map { file -> tuple(file.baseName - ~/\.gz/, file) }
    .transpose()
    .set { vcf_filename_tracker_added }
  

  extract_ids_from_vcf_and_create_index(vcf_filename_tracker_added)
  find_duplicated_ids(extract_ids_from_vcf_and_create_index.out)

  vcf_filename_tracker_added
    .join(find_duplicated_ids.out, by:0)
    .set { to_extract_vcf }
  extract_from_vcf(to_extract_vcf)

  change_extracted_vcf(extract_from_vcf.out)

  vcf_filename_tracker_added
    .map { it1, it2 -> tuple(it1,it2,file("${it2}.tbi")) }
    .join(change_extracted_vcf.out, by:0)
    .set { to_replace_vcfs }

  insert_the_new_dup_names(to_replace_vcfs)

}


