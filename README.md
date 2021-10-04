# duplicate_id_resolver
characterize and manipulate duplicate IDs in VCFs

## Introduction
Right now this tool is built to add information to an in-house imputation project, but it is written to be used on any vcf file. For speed purposes, we use the dbsnp reference data from the cleansumstats pipeline. If necessary, I will add in this package how to create the used dbsnp reference data format from scratch.

## Run the script
It is possible to submit a set of vcf files, each will be given a map file with all coordinates according to dbsnp151

```
# install nextflow using mamba (requires conda/mamba)
mamba create -n duplicate_id_resolver --channel bioconda \
  nextflow==20.10.0 \
  bcftools=1.9 \
  tabix

# Activate environment
conda activate duplicate_id_resolver

# Run a single file with duplicates
nextflow characterize_dup_IDs.nf --input 'data/1kgp/GRCh37/GRCh37_example_data_duplicates.vcf.gz'

# Run a single file without duplicates
nextflow characterize_dup_IDs.nf --input 'data/1kgp/GRCh37/GRCh37_example_data.vcf.gz'

# Check output
zcat out/mapfiles/GRCh37_example_data.vcf.map.gz | head | column -t
```

## DEV

### Download source 1000G
```
# Download required files
for chr in {20..22};do
  wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.chr${chr}.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz
done 
```

### create example data from 1000G
```
# extract header
zcat ALL.chr22.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz | grep "#"  > tmp1

# extract a subset
for chr in {20..22};do
  zcat ALL.chr${chr}.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz | grep -v "#" | head -n100 >> tmp2
done

# sort and make tabix index
sort -t "$(printf '\t')" -k1,1 -k2,2n tmp2 > tmp2b

# merge with header
cat tmp1 tmp2b > tmp3

# bgzip and tabix (so that we can use bcftools)
bgzip -c tmp3 > GRCh37_example_data.vcf.gz
tabix -p vcf GRCh37_example_data.vcf.gz

# Add new example data to the example data folder
mv GRCh* data/1kgp/GRCh37/

# remove tmp files (careful!)
# rm tmp*
```

### create example data with duplicates
Make some duplicates from existing example data
```
#extract header
zcat data/1kgp/GRCh37/GRCh37_example_data.vcf.gz | grep "#"  > tmp1

#take out 5 random rows to use as duplicates
zcat data/1kgp/GRCh37/GRCh37_example_data.vcf.gz | awk '
  $0 !~ "#"{print $0}
  NR==20{print $0}
  NR==134{print $0}
  NR==354{print $0}
  NR==687{print $0}
  NR==870{print $0}
' > tmp2

# sort and make tabix index
sort -t "$(printf '\t')" -k2,1 -k2,2n tmp2 > tmp2b

# merge with header
cat tmp1 tmp2b > tmp3

# bgzip and tabix (so that we can use bcftools)
bgzip -c tmp3 > GRCh37_example_data_duplicates.vcf.gz
tabix -p vcf GRCh37_example_data_duplicates.vcf.gz

# Add new example data to the example data folder
mv GRCh* data/1kgp/GRCh37/

# remove tmp files (careful!)
# rm tmp*
```
