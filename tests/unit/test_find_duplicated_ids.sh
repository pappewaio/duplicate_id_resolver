#!/usr/bin/env bash

set -euo pipefail

test_script="find_duplicated_ids"
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

  "${test_script}.sh" ./input.txt > ./observed-result.txt

  _check_results ./observed-result.txt ./expected-result.txt

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Check that one duplicate can be found

_setup "find one duplicated id"

cat <<EOF > ./input.txt
7 rs228729
8 rs12754538
8 rs12754538
9 rs2480782
EOF

cat <<EOF > ./expected-result.txt
8	rs12754538
8	rs12754538
EOF

_run_script

#---------------------------------------------------------------------------------
# Check that two duplicate can be found and in right order
# Right order is the rowindex

_setup "find two duplicated ids and test order 1 of 2"

cat <<EOF > ./input.txt
7 rs228729
7 rs228729
8 rs12754538
8 rs12754538
9 rs2480782
EOF

cat <<EOF > ./expected-result.txt
7	rs228729
7	rs228729
8	rs12754538
8	rs12754538
EOF

_run_script

#---------------------------------------------------------------------------------
# Check that two duplicate can be found and in right order
# Right order is the rowindex

_setup "find two duplicated ids and test order 2 of 2"

cat <<EOF > ./input.txt
8 rs12754538
8 rs12754538
7 rs228729
7 rs228729
9 rs2480782
EOF

cat <<EOF > ./expected-result.txt
7	rs228729
7	rs228729
8	rs12754538
8	rs12754538
EOF

_run_script

#---------------------------------------------------------------------------------
# Check that two duplicate can be found and in right order
# Right order is the rowindex

_setup "find three duplicated ids"

cat <<EOF > ./input.txt
8 rs12754538
8 rs12754538
7 rs228729
7 rs228729
7 rs228729
9 rs2480782
EOF

cat <<EOF > ./expected-result.txt
7	rs228729
7	rs228729
7	rs228729
8	rs12754538
8	rs12754538
EOF

_run_script

#---------------------------------------------------------------------------------
# Next case








