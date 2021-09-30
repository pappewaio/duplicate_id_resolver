# Infile
infile=$1

# Extract all ids from vcf and create indices
zcat ${infile} | awk '!/^#/{print  NR, $3}'

