
infile=${1}

bcftools plugin fill-tags ${infile} -Ou -- --tags 'AF,AC,AN' | bcftools query -f'%CHROM\t%POS\t%ID\t%REF\t%ALT\t%AN\t%AC\t%AF\n' 



#FROM BCFTOOLS manual (aalthough too confusing output from bcftools stats, so using fill-tags plugin and query command above)
# By default the allele frequency is estimated from AC/AN, if available, or directly from the genotypes (GT) if not.
# When one VCF file is specified on the command line, then stats by non-reference allele frequency
# -So make sure that the infile is absent of AC AN fields
#bcftools stats ${infile} 
