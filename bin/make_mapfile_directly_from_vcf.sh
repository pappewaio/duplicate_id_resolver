infile=$1
outfile=$2

echo -e "ROWINDEX CHR POS ID REF ALT S1 S2 S3 S4 S5 NEWID" > ${outfile}
zcat ${infile} | awk '!/^#/{print  NR, $1, $2, $3, $4, $5,"0","0","0","0","0",$3}' >> ${outfile}
gzip -c ${outfile} >  ${outfile}.gz

