args = commandArgs(trailingOnly=TRUE)

infile <- args[1]
outdir <- args[2]
outprefix <- args[3]

#infile=""
#outdir="out/allele_freq_tabularizes"
#outprefix="chr22_"
#
##multiplicates > 2 ids that are same
#system("cat <<EOF > /tmp/test_allele_freq_characterization.tsv
#CHROM	POS	ID	REF	ALT	AN	AC	AF
#22	16050075	2	A	G	5008	1	0.000199681
#22	16050075	2	A	C	5008	1	0.000299681
#22	16050115	1	G	A	5008	32	0.00838978
#22	16050115	1	G	T	5008	32	0.00638978
#22	16050213	3	C	A	5008	38	0.00758786
#22	16050213	3	C	C	5008	38	0.00758786
#22	16050213	3	C	G	5008	38	0.00758786
#22	17050213	4	G	T	5008	38	0.00758786
#22	16050213	5	A	C	5008	38	0.00758786
#22	16050213	5	C	G	5008	38	0.00758786
#22	16050213	6	A	C	5008	38	0.33758786
#22	16050213	6	A	G	5008	38	0.03258786
#22	16050213	7	A	C	5008	38	0.53758786
#22	16050213	7	A	G	5008	38	0.05258786
#EOF
#")
#
#ta <- read.table("/tmp/test_allele_freq_characterization.tsv", header=TRUE,sep="\t", stringsAsFactors=FALSE)

ta <- read.table(infile, header=TRUE,sep="\t", stringsAsFactors=FALSE)

.get_multiplicates_index <- function(x, th){
  le <- unlist(lapply(split(x,x), length))
  nix <- names(le[le>th])
  which(x %in% nix)
}

.get_selection_by_index <- function(x,ix){
  x[ix,]
}

.merge_dups <- function(ta){
  # get every 2nd row
  ta <- ta[order(ta[,"ID"]),]
  a <- ta[seq(1,by=2,length=nrow(ta)/2),]
  b <- ta[seq(2,by=2,length=nrow(ta)/2),]
  # cbind the tables
  cbind(a,b[,c("REF","ALT","AC","AF")])
}

.ref_not_agree_for_dups <- function(ta){
  which(ta[,4]!=ta[,9])
}

.non_multiplicates <- function(ta,ix){
  ta[-ix,]
}

.joint_highest_freq <- function(ta){
  a <- ta[,8]>=ta[,12]
  b <- ta[,8]<ta[,12]
  c <- rep(NA,nrow(ta))
  c[a] <- ta[a,8]
  c[b] <- ta[b,12]
  c
}
.joint_lowest_freq <- function(ta){
  a <- ta[,8]>=ta[,12]
  b <- ta[,8]<ta[,12]
  c <- rep(NA,nrow(ta))
  c[a] <- ta[a,12]
  c[b] <- ta[b,8]
  c
}

# Test if a non duplicate entry exists (and stop this function, if so)
ix <- .get_multiplicates_index(ta[,"ID"], 1)

check0 <- .non_multiplicates(ta,ix)
write.table(check0, file=paste(outdir,"/",outprefix,"non-multiplicates.tsv", sep=""), sep="\t", row.names=FALSE, quote=FALSE)
ta <- ta[ix,]

# if multiplicates, remove and write to file
ix <- .get_multiplicates_index(ta[,"ID"], 2)
check1 <-.get_selection_by_index(ta, ix)
write.table(check1, file=paste(outdir,"/",outprefix,"triplicates-or-more.tsv", sep=""), sep="\t", row.names=FALSE, quote=FALSE)
if(length(ix)>0){
  ta <- .get_selection_by_index(ta, -ix)
}

# merge dups
ta <- .merge_dups(ta)

# sanity check 2
ix <- .ref_not_agree_for_dups(ta)
check2 <- ta[ix,]
write.table(check2, file=paste(outdir,"/",outprefix,"ref_not_agree_for_dups.tsv", sep=""), sep="\t", row.names=FALSE, quote=FALSE)
#remove not agreeing dups
if(length(ix)>0){
  ta <- ta[-ix,]
}

# add joint freq
a <- .joint_lowest_freq(ta)
b <- .joint_highest_freq(ta)


# Bin frequencies
bins <- c(0,0.001,0.01,seq(from=0.1, to=1, by=0.1))
a.binned <- cut(a, breaks = bins)
b.binned <- cut(b, breaks = bins)

lowest.distr <- as.data.frame(table(a.binned))
highest.distr <- as.data.frame(table(b.binned))

# write distribution
write.table(lowest.distr, file=paste(outdir,"/",outprefix,"lowest-freq-of-pairs-distributon", sep=""), sep="\t", row.names=FALSE, quote=FALSE)
write.table(highest.distr, file=paste(outdir,"/",outprefix,"highest-freq-of-pairs-distributon", sep=""), sep="\t", row.names=FALSE, quote=FALSE)

