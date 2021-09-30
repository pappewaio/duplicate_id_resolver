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

# Run a single file
nextflow characterize_dup_IDs.nf --input 'data/1kgp/GRCh37/GRCh37_example_data.vcf.gz'

# Check output
zcat out/mapfiles/GRCh37_example_data.vcf.map.gz | head | column -t
```


