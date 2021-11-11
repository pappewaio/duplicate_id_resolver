map=$1
replacefile=$2
out=$3

#out should have extension .vcf.gz

# prepare mapfile as tabix sorted vcf
cat <<EOF > tmp1
##fileformat=VCFv4.3
##FILTER=<ID=PASS,Description="All filters passed">
##fileDate=20211010
##source=exampleTestData
##INFO=<ID=AN,Number=1,Type=Integer,Description="Total number of alleles in called genotypes">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
EOF

# use replacefile as new rsid
gunzip -c ${map} | awk -vOFS='\t' -vfile2="${replacefile}" '
BEGIN{getline var < file2}
NR>1{ 
  getline var < file2
  split(var,sp," ")
  print $2, $3, sp[2], $5, $6, ".", "PASS", "AN=5096" 
}
' > tmp2

# sort and make tabix index
sort -t "$(printf '\t')" -k1,1 -k2,2n tmp2 > tmp2b

# merge with header
cat tmp1 tmp2b > tmp3

# bgzip and tabix (so that we can use bcftools)
bgzip -c tmp3 > ${out}
tabix -p vcf ${out}

