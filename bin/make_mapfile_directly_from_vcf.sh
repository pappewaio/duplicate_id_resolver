infile=$1
outfile=$2

echo -e "ROWINDEX CHR POS ID REF ALT" > ${outfile}
zcat ${infile} | awk '!/^#/{print  NR, $1, $2, $3, $4, $5,"0","0","0","0","0",$4}' >> ${outfile}
gzip -c ${outfile} >  ${outfile}.gz

