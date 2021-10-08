# duplicate_id_resolver
characterize and manipulate duplicate IDs in VCFs

## Introduction
Right now this tool is built to add information to an in-house imputation project, but it is written to be used on any vcf file.

## Run the script
It is possible to submit a set of vcf files, if they have similar names and are placed in the same directory. This can be achieved by symlinking to a temp diretory if required.

```
# install nextflow using mamba (requires conda/mamba)
mamba create -n duplicate_id_resolver --channel bioconda \
  nextflow==20.10.0 \
  bcftools=1.9 \
  tabix

# Activate environment
conda activate duplicate_id_resolver

# Run a single file with duplicates (right now with triplicates)
nextflow characterize_dup_IDs.nf --input 'data/1kgp/GRCh37/GRCh37_example_data_duplicates.vcf.gz'

# Run a single file without duplicates (right now with triplicates)
nextflow characterize_dup_IDs.nf --input 'data/1kgp/GRCh37/GRCh37_example_data.vcf.gz'

# Check output
cat out/allele_freqs/GRCh37_example_data_duplicates.vcf_allele_freqs | head | column -t

# Run multiple files in parallell(using '*')
nextflow characterize_dup_IDs.nf --input 'data/1kgp/GRCh37/GRCh37_example_data*.vcf.gz'

```

## DEV

### Run unit tests

```
# Activate environment
conda activate duplicate_id_resolver

# Run tests
./tests/run-unit-tests.sh
```

### Download source 1000G
```
# Download required files
for chr in {20..22};do
  wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.chr${chr}.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz
done 
```

### create example data from 1000G
```
for chr in {20..22};do
  zcat ALL.chr22.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz | head -n1000 > tmp1_chr${chr}
done

bcftools concat -Oz tmp1_chr20 tmp1_chr21 tmp1_chr22 > tmp2_chr20-22.vcf.gz

#clean temp files
```

### Data without AC or AN
This is to make sure that AF is counted directly using GT field genotypes.

```
bcftools annotate -Oz -x INFO/AN,INFO/AC tmp2_chr20-22.vcf.gz > tmp2.vcf.gz
```

### create example data with duplicates and tabix index dup and non dup version
Make some duplicates from existing example data
```
# Extract header
zcat tmp2.vcf.gz | grep "#"  > tmp2_header
zcat tmp2.vcf.gz | grep -v "#" > tmp2_rest

# Take out 5 random rows to use as duplicates
cat tmp2_rest <( awk '
  NR==20{print $0}
  NR==134{print $0}
  NR==354{print $0}
  NR==687{print $0}
  NR==870{print $0}
' tmp2_rest) > tmp2_rest_dup

# sort and make tabix index
sort -t "$(printf '\t')" -k2,1 -k2,2n tmp2_rest > tmp2b
sort -t "$(printf '\t')" -k2,1 -k2,2n tmp2_rest_dup > tmp2b_dup

# merge with header
cat tmp2_header tmp2b > tmp3
cat tmp2_header tmp2b_dup > tmp3_dup

# bgzip and tabix (so that we can use bcftools)
bgzip -c tmp3 > GRCh37_example_data.vcf.gz
bgzip -c tmp3_dup > GRCh37_example_data_duplicates.vcf.gz

tabix -p vcf GRCh37_example_data.vcf.gz
tabix -p vcf GRCh37_example_data_duplicates.vcf.gz

#remove tmp files
```

