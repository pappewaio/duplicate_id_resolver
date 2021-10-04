
infile=${1}

#FROM BCFTOOLS manual
# By default the allele frequency is estimated from AC/AN, if available, or directly from the genotypes (GT) if not.
#When one VCF file is specified on the command line, then stats by non-reference allele frequency
bcftools stats --af-tag GT ${infile} 

