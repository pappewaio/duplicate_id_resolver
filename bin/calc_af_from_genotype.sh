
infile=${1}

bcftools query -f'%CHROM\t%POS\t%REF\t%ALT\t%AN\t%AC\t%AF\n' ${infile}





#FROM BCFTOOLS manual (aalthough too confusing output)
# By default the allele frequency is estimated from AC/AN, if available, or directly from the genotypes (GT) if not.
# When one VCF file is specified on the command line, then stats by non-reference allele frequency
# -So make sure that the infile is absent of AC AN fields
#bcftools stats ${infile} 
