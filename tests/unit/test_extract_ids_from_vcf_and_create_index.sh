#!/usr/bin/env bash

set -euo pipefail

test_script="extract_ids_from_vcf_and_create_index"
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

  "${test_script}.sh" ./input.vcf.gz > ./observed-result.txt

  _check_results ./observed-result.txt ./expected-result.txt

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Check that the final output is what we think it is

_setup "Simple test"

cat <<EOF | gzip -c > ./input.vcf.gz
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

cat <<EOF > ./expected-result.txt
7 rs228729
8 rs12754538
9 rs2480782
EOF

_run_script

#---------------------------------------------------------------------------------
# Next case

