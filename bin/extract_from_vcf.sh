infile1=$1
infile2=$2
outfile=$3

# Add index, etc

#extract header
zcat ${infile2} | grep "#"  > tmp1

#take out 5 random rows to use as duplicates
awk 'NR==FNR{a[$1];next} FNR in a{print $0}' ${infile1} <(zcat ${infile2}) > tmp2

# sort and make tabix index
sort -t "$(printf '\t')" -k1,1 -k2,2n tmp2 > tmp2b

# merge with header
cat tmp1 tmp2b > tmp3

# bgzip and tabix (so that we can use bcftools)
bgzip -c tmp3 > ${outfile}
tabix -p vcf ${outfile}

