args = commandArgs(trailingOnly=TRUE)

indir <- args[1]
pattern <- args[2]
outdir <- args[3]
outname <- args[4]

#indir="/tmp/test_allele_freq_distr"
#pattern="allele_freq_distr"
#outdir="out/allele_freq_summary"
#outprefix="cohort5_"
##
###multiplicates > 2 ids that are same
#system("mkdir -p /tmp/test_allele_freq_distr")
#system("cat <<EOF > /tmp/test_allele_freq_distr/test1_allele_freq_distr.tsv
#b.binned	Freq
#(0,0.001]	2
#(0.001,0.01]	2
#(0.01,0.1]	0
#(0.1,0.2]	0
#(0.2,0.3]	1
#(0.3,0.4]	0
#(0.4,0.5]	0
#(0.5,0.6]	0
#(0.6,0.7]	0
#(0.7,0.8]	0
#(0.8,0.9]	0
#(0.9,1]	0
#EOF
#")
#system("cat <<EOF > /tmp/test_allele_freq_distr/test2_allele_freq_distr.tsv
#b.binned	Freq
#(0,0.001]	2
#(0.001,0.01]	2
#(0.01,0.1]	0
#(0.1,0.2]	0
#(0.2,0.3]	1
#(0.3,0.4]	0
#(0.4,0.5]	0
#(0.5,0.6]	0
#(0.6,0.7]	0
#(0.7,0.8]	0
#(0.8,0.9]	0
#(0.9,1]	0
#EOF
#")

# get full path for each file for selected pattern
fl <- list.files(indir, full.names=TRUE)
fl <- fl[grep(pattern,fl)]

# Sort files based on name
fl <- sort(fl)

# extract prefix to use as column names
prf <- sub("_.*","",basename(fl), perl=TRUE)

all <- list()
for(i in 1:length(fl)){
  ta <- read.table(fl[i], header=TRUE, stringsAsFactors=FALSE, row.names=1)
  colnames(ta) <- prf[i]
  all[[i]] <- ta
}


# merge
rownames <- all[[1]]
rownames[,1] <- rownames(rownames)
colnames(rownames) <- "bins"
all.merge <- do.call("cbind", c(rownames, all))

total <- apply(all.merge[,2:ncol(all.merge)],1,sum)
all.merge[,"total"] <- total

system(paste("mkdir -p ",outdir, sep=""))
write.table(all.merge, file=paste(outdir,"/",outname, sep=""), sep="\t", row.names=FALSE, quote=FALSE)

