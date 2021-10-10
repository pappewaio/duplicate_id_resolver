vcfin=$1
vcfmap=$2
out=$3

# use bcftools to annotate
# if . is the id used to replace, then the original will be kept
bcftools annotate -a ${vcfmap} -c ID ${vcfin} -Oz -o${out}
tabix -p vcf ${out}



