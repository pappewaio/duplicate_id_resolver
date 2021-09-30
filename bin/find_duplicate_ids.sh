infile=$1

LC_ALL=C sort -k2,2 ${infile} > sort.tmp
awk '{print $2}' sort.tmp | uniq -d  > duplicated_ids
LC_ALL=C join -1 1 -2 2 duplicated_ids sort.tmp | awk -vOFS="\t" '{print $2, $1}' | sort -k1,1 -n

