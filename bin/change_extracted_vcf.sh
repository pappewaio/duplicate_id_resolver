infile=${1}
outfile=${2}


zcat ${infile} | grep "#"  > tmp2_header
zcat ${infile} | grep -v "#" > tmp2_rest

awk -vOFS="\t" '
  {$3=$1"_"$2"_"$4"_"$5; print $0}
' tmp2_rest > tmp2_rest_changed

# sort and make tabix index
sort -t "$(printf '\t')" -k2,1 -k2,2n tmp2_rest_changed > tmp2b

# merge with header
cat tmp2_header tmp2b > tmp3

# bgzip and tabix (so that we can use bcftools)
bgzip -c tmp3 > ${outfile}

tabix -p vcf ${outfile}
