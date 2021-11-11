#!/usr/bin/env bash

set -euo pipefail

test_script="join_input_and_map"
initial_dir=$(pwd)"/${test_script}"
curr_case=""

mkdir "${initial_dir}"
cd "${initial_dir}"

#=================================================================================
# Helpers
#=================================================================================

function _setup {
  mkdir "${1}"
  cd "${1}"
  curr_case="${1}"
}

function _check_results {
  obs=$1
  exp=$2
  if ! diff ${obs} ${exp} &> ./difference; then
    echo "- [FAIL] ${curr_case}"
    cat ./difference 
    exit 1
  fi

}

function _run_script {

  "${test_script}.sh" ./input.vcf.gz ./input2.vcf.gz ./observed-result.vcf.gz

  _check_results <(zcat ./observed-result.vcf.gz | grep -v "##") <(zcat ./expected-result.vcf.gz | grep -v "##")

  echo "- [OK] ${curr_case}"

  _check_results <(bcftools index --nrecords ./observed-result.vcf.gz) <(bcftools index --nrecords ./expected-result.vcf.gz)

  echo "- [OK] ${curr_case} row test"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Check that the final output is what we think it is

_setup "Change IDs in vcf"

# file to use as source file
cat <<EOF | bgzip -c > ./input.vcf.gz
##fileformat=VCFv4.3
##FILTER=<ID=PASS,Description="All filters passed">
##fileDate=20210505
##source=exampleTestData
##INFO=<ID=AN,Number=1,Type=Integer,Description="Total number of alleles in called genotypes">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
1	7845695	rs228729	T	C	.	PASS	AN=5096
1	8473813	rs12754538	C	T	.	PASS	AN=5096
1	10593296	rs2480782	G	T	.	PASS	AN=5096
EOF
tabix -p vcf ./input.vcf.gz

# file to use for annotation
cat <<EOF | bgzip -c > ./input2.vcf.gz
##fileformat=VCFv4.3
##FILTER=<ID=PASS,Description="All filters passed">
##fileDate=20210505
##source=exampleTestData
##INFO=<ID=AN,Number=1,Type=Integer,Description="Total number of alleles in called genotypes">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
1	8473813	rs000000	C	T	.	PASS	AN=5096
1	10593296	rs2480782	G	T	.	PASS	AN=5096
EOF
tabix -p vcf ./input2.vcf.gz

cat <<EOF | bgzip -c > ./expected-result.vcf.gz
##fileformat=VCFv4.3
##FILTER=<ID=PASS,Description="All filters passed">
##fileDate=20210505
##source=exampleTestData
##INFO=<ID=AN,Number=1,Type=Integer,Description="Total number of alleles in called genotypes">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
1	7845695	rs228729	T	C	.	PASS	AN=5096
1	8473813	rs000000	C	T	.	PASS	AN=5096
1	10593296	rs2480782	G	T	.	PASS	AN=5096
EOF
tabix -p vcf ./expected-result.vcf.gz

_run_script

#---------------------------------------------------------------------------------
# Next case

