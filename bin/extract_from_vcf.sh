infile1=$1
infile2=$2

awk 'NR==FNR{a[$1];next} FNR in a{print $0}' ${infile1} <(zcat ${infile2})


