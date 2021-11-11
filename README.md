# duplicate_id_resolver
characterize and manipulate duplicate IDs in VCFs

Version: 1.0.0

## Introduction
Right now this tool is built to add information to an in-house imputation project, but it is written to be used on any vcf file.

## Step 1
It is possible to submit a set of vcf files, if they have similar names and are placed in the same directory. This can be achieved by symlinking to a temp diretory if required.

```
# install nextflow using mamba (requires conda/mamba)
mamba create -n duplicate_id_resolver --channel bioconda \
  nextflow==20.10.0 \
  bcftools=1.9 \
  tabix \
  r-base

# Activate environment
conda activate duplicate_id_resolver

# Run a single file with duplicates
nextflow characterize_dup_IDs.nf --input 'data/1kgp/GRCh37/GRCh37_example_data_duplicates.vcf.gz'

# Run a single file without duplicates
nextflow characterize_dup_IDs.nf --input 'data/1kgp/GRCh37/GRCh37_example_data.vcf.gz'

# Check output
cat out/allele_freqs/GRCh37_example_data_duplicates.vcf_allele_freqs | head | column -t

# Run multiple files in parallell(using '*')
nextflow characterize_dup_IDs.nf --input 'data/1kgp/GRCh37/GRCh37_example_data*.vcf.gz'

```

## Step 2
The output from the first step can be analyzed a bit more regarding their frequencies:
- Remove all entries with more than two of the same ID
- Tabularize all 
- bin allele frequecies
- Create a distributional chart

This is most easily done using R as the files are much smaller than the original vcfs

```
mkdir -p out/allele_freq_tabularizes 
Rscript bin/summarize_allele_freqs.R \
  "out/allele_freqs/GRCh37_example_data_duplicates.vcf_allele_freqs" \
  "out/allele_freq_tabularizes" \
  "chr22_"
```

## Step 3
The output from the second step can be combined to one file per experiment/cohort

```
mkdir -p out/allele_freq_summary
Rscript bin/summarize_allele_freqs_merge.R \
    "out/allele_freq_tabularizes" \
    "highest-freq-of-pairs-distributon" \
    "out/allele_freq_summary" \
    "cohort5_highest-freq-of-pairs-distributon"
```

## Step 4
Run this code to replace all duplicates with their chr_pos_ref_alt ID to make them unique. In this way we won't lose any data except the link to rsid, which we will keep in a metadata file in case someone needs it. 

```
# Run a single file with duplicates
nextflow replace_dup_IDs_with_chrposrefalt.nf --input 'data/1kgp/GRCh37/GRCh37_example_data_duplicates.vcf.gz' 
```

## Step 5 - Replace ids in QC-files
Use the output from step 4 to replace IDs in QC files

For this to work, we can create mapfiles, which can be fed into the pipeline `replace_rsid_in_qcfiles`, which we will symlink into this repository.

```
# make mapfiles (but use only the location informative part, and ID)
mkdir -p out/mapfiles
infile="out/updated_vcf/GRCh37_example_data_duplicates.vcf.gz"
outfile="out/mapfiles/$(basename ${infile%.vcf.gz})_mapfile"
./bin/make_mapfile_directly_from_vcf.sh ${infile} ${outfile}

```

IF there are many mapfiles that corresponds to one qc file, then this is the time to merge the mapfiles into one file, which then can be used using the code below.

```
# Symlink auxillary repo
ln -s ../replace_rsid_in_qcfiles .

# Run a single file - example data 1
nextflow run replace_rsid_in_qcfiles/replace_rsid_in_qcfile_from_mapfiles.nf --input 'data/runfile/runfile1.txt' --outdir out

```

## Background and mapping strategy
A previous mapping has been done to the VCF file that produces the QC-file-that is being mapped again here

The approach will be:
We can use the produced mapfiles and match on chromosome_position_ref_alt information. This require the steps:
1) Merge all mapfiles
2) Add rownumber to qc-file
3) sort both mapfile and qc file on chromosome_position_ref_alt
4) check that there are no duplicates of this index
5) use unix join to align the information
6) check that everything had a match
7) prepare final output using the updated rsid

Notes:
Step 1) the merge of all mapfiles (if they are separated by e.g., chromosome), will be done outside the pipeline using a simple 'cat' command.

Step 4) A sort -u is done, and need to be followed up by comparing wc -l to all files and make sure they are same lenghts.

A final validifier that everything went ok and no rows were left behind is to scan throuvh the check files in 'out/nr_checks'


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
# Make entries so we not only have '.'
# exclude multiallelics (which we will synthetically make as duplicates later)
# and select only first 1000 rows
for chr in {20..22};do
  # save header
  zcat ALL.chr${chr}.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz \
  | head -n10000 | awk '$0~"#" {print $0}' > tmp_header_chr${chr}

  zcat ALL.chr${chr}.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz \
  | awk -vOFS="\t" '
      $0!~"#" && $5!~"," {$3=$1"_"$2"_"$4"_"$5; print $0}
    ' \
  | head -n1000 \
  > tmp_body_chr${chr}

  # sort body
  sort -t "$(printf '\t')" -k2,1 -k2,2n tmp_body_chr${chr} > tmp_body_chr${chr}_sorted
  
  # add header
  cat tmp_header_chr${chr} tmp_body_chr${chr}_sorted > tmp1_chr${chr}

  # bgzip
  bgzip -c tmp1_chr${chr} > tmp1_chr${chr}.gz

  # index
  tabix -p vcf tmp1_chr${chr}.gz
done

bcftools concat -Oz tmp1_chr20.gz tmp1_chr21.gz tmp1_chr22.gz > tmp2_chr20-22.vcf.gz

#clean temp files
```

### Data without AC or AN
This is to make sure that AF is counted directly using GT field genotypes. Also remove the other INFO fields to be able to smoothly swap the alt allele for the duplicates

```
# Remove AN and AF
bcftools annotate -Oz -x INFO/AN,INFO/AC tmp2_chr20-22.vcf.gz > tmp2.vcf.gz
# Remove the rest
bcftools annotate -Oz -x INFO tmp2.vcf.gz > tmp3.vcf.gz
```

### create example data with duplicates and tabix index dup and non dup version
Make some duplicates from existing example data
```
# Extract header
zcat tmp3.vcf.gz | grep "#"  > tmp2_header
zcat tmp3.vcf.gz | grep -v "#" > tmp2_rest

# Take out 5 random rows to use as duplicates (set alt <- ref to not have complete duplicates)
awk -vOFS="\t" '
  NR==20{$3="dup1"; print $0; $5="A"; print $0}
  NR==134{$3="dup2"; print $0; $5="A";print $0}
  NR==354{$3="dup3"; print $0; $5="A";print $0}
  NR==687{$3="dup4"; print $0; $5="A";print $0}
  NR==870{$3="dup5"; print $0; $5="A";print $0}
  NR!=20 && NR!=134 && NR!=354 && NR!=687 && NR!=870 {print $0} 
  ' tmp2_rest > tmp2_rest_dup

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

### imputeQualityMetrics example data
MAF and the other stats will just be 0.1, 0.2, 0.3, etc (which should be fine as we intend to only modify column 3 the rsID)

```
mkdir -p data/imputeQCmetrics
echo -e "CHR POS ID REF ALT MAF AR2 DR2 Hwe DR2 Accuracy Score" > data/imputeQCmetrics/imputeQualityMetrics.txt
zcat data/1kgp/GRCh37/GRCh37_example_data.vcf.gz | grep -v "#" | awk '{print $1, $2, $3, $4, $5, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7 }'  >> data/imputeQCmetrics/imputeQualityMetrics.txt

echo -e "CHR POS ID REF ALT MAF AR2 DR2 Hwe DR2 Accuracy Score" > data/imputeQCmetrics/imputeQualityMetrics_dup.txt
zcat data/1kgp/GRCh37/GRCh37_example_data_duplicates.vcf.gz | grep -v "#" | awk '{print $1, $2, $3, $4, $5, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7 }'  >> data/imputeQCmetrics/imputeQualityMetrics_dup.txt

# zip it
gzip -c data/imputeQCmetrics/imputeQualityMetrics.txt > data/imputeQCmetrics/imputeQualityMetrics.txt.gz 
gzip -c data/imputeQCmetrics/imputeQualityMetrics_dup.txt > data/imputeQCmetrics/imputeQualityMetrics_dup.txt.gz 
rm data/imputeQCmetrics/imputeQualityMetrics.txt
rm data/imputeQCmetrics/imputeQualityMetrics_dup.txt

#inspect files
zcat data/imputeQCmetrics/imputeQualityMetrics.txt.gz | tail
zcat data/imputeQCmetrics/imputeQualityMetrics_dup.txt.gz | tail


```

### SNP_QC.out example data
MAF and the other stats will just be 0.1, 0.2, 0.3, etc (which should be fine as we intend to only modify column 3 the rsID)

```
mkdir -p data/SNP_QC
echo -e "CHROM POSITION ID REF ALT GenotypeWaveAssociation ImputeBatchAssociation HWE MAF ImputeRsq SamplePlateAssociation SSIPlateAssociation" > data/SNP_QC/SNP_QC.out
zcat data/1kgp/GRCh37/GRCh37_example_data.vcf.gz | tail -n+2 | awk '{print $1, $2, $3, $4, $5, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7 }' >> data/SNP_QC/SNP_QC.out

echo -e "CHROM POSITION ID REF ALT GenotypeWaveAssociation ImputeBatchAssociation HWE MAF ImputeRsq SamplePlateAssociation SSIPlateAssociation" > data/SNP_QC/SNP_QC_dup.out
zcat data/1kgp/GRCh37/GRCh37_example_data_duplicates.vcf.gz | tail -n+2 | awk '{print $1, $2, $3, $4, $5, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7 }' >> data/SNP_QC/SNP_QC_dup.out

#zip it
gzip -c data/SNP_QC/SNP_QC.out > data/SNP_QC/SNP_QC.out.gz 
gzip -c data/SNP_QC/SNP_QC_dup.out > data/SNP_QC/SNP_QC_dup.out.gz 
rm data/SNP_QC/SNP_QC.out
rm data/SNP_QC/SNP_QC_dup.out

#inspect file
zcat data/SNP_QC/SNP_QC.out.gz | tail
zcat data/SNP_QC/SNP_QC_dup.out.gz | tail



```

