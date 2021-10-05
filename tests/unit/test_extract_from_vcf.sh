#!/usr/bin/env bash

set -euo pipefail

test_script="extract_from_vcf"
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

  "${test_script}.sh" ./input2.txt ./input1.vcf.gz ./observed-result1.vcf.gz 

  _check_results <(gunzip -c ./observed-result1.vcf.gz) <(gunzip -c ./expected-result1.vcf.gz)

  if [ ! -f  ./observed-result1.vcf.gz.tbi ]; then
    echo "no tabix index genereated"
    exit 1;
  fi

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Check that two duplicate can be found and in right order
# Right order is the rowindex

_setup "extract two groups of duplicated ids"

cat <<EOF > ./input2.txt
8 rs12754538
9 rs12754538
10 rs228729
11 rs228729
12 rs228729
EOF

cat <<EOF | bgzip -c > ./input1.vcf.gz
##fileformat=VCFv4.3
##FILTER=<ID=PASS,Description="All filters passed">
##fileDate=20210505
##source=exampleTestData
##INFO=<ID=AN,Number=1,Type=Integer,Description="Total number of alleles in called genotypes">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
1	7845695	rs828729	T	C	.	PASS	AN=5096
1	8473813	rs12754538	C	T	.	PASS	AN=5096
1	10593296	rs12754538	G	T	.	PASS	AN=5096
1	7845695	rs228729	T	C	.	PASS	AN=5096
1	8473813	rs228729	C	T	.	PASS	AN=5096
1	10593296	rs928729	G	T	.	PASS	AN=5096
1	10593296	rs2480782	G	T	.	PASS	AN=5096
1	10593296	rs528729	G	T	.	PASS	AN=5096
EOF

cat <<EOF | bgzip -c > ./expected-result1.vcf.gz
##fileformat=VCFv4.3
##FILTER=<ID=PASS,Description="All filters passed">
##fileDate=20210505
##source=exampleTestData
##INFO=<ID=AN,Number=1,Type=Integer,Description="Total number of alleles in called genotypes">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
1	7845695	rs228729	T	C	.	PASS	AN=5096
1	8473813	rs12754538	C	T	.	PASS	AN=5096
1	8473813	rs228729	C	T	.	PASS	AN=5096
1	10593296	rs12754538	G	T	.	PASS	AN=5096
1	10593296	rs928729	G	T	.	PASS	AN=5096
EOF

_run_script

#---------------------------------------------------------------------------------
# Next case








