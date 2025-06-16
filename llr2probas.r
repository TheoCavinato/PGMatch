suppressPackageStartupMessages(library(R.utils))
library(data.table)
library(argparse)
library(mvtnorm)
library(PearsonDS)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# Create parser object
parser <- ArgumentParser()

# Add arguments
parser$add_argument("--llr", help="Input LLR", required=T)
parser$add_argument("--moments", help="Input moments", required=T)
parser$add_argument("--probas", help="Output file for probabilities", required=T)

# Parse the args
args <- parser$parse_args()

#------------------------------------------------------------------------------#
# Import moments
#------------------------------------------------------------------------------#
moments_df = fread(args$moments)
llr1_moments = as.vector(unlist(moments_df[1,]))
llr0_moments = as.vector(unlist(moments_df[2,]))

#------------------------------------------------------------------------------#
# Import llr
#------------------------------------------------------------------------------#
llr_testing= as.matrix(fread(args$llr, hea=T))
cat("LLR imported\n")

#------------------------------------------------------------------------------#
# Compute probas
#------------------------------------------------------------------------------#

# COMPUTE PROBA
# check if the data come from llr_computation.r or llr_computation_all_vs_all.r
if (ncol(llr_testing) == nrow(llr_testing)){ 
	# comes from llr_computation_all_vs_all.r
	p0 = dpearson(llr_testing, moments=llr0_moments)
	p1 = dpearson(llr_testing, moments=llr1_moments)

	# for positions with both p0 and p1 == 0.0, these means that the values were extreme
	# so find the direction of the extreme value and adapt
	p1[which(p0==0.0 & p1==0.0, arr.ind=T)] = 0.0
	p0[which(p0==0.0 & p1==0.0, arr.ind=T)] = 1.0

	p1[which(p1 == 0.0 & p0 == 0.0 & llr_testing > llr1_moments[1], arr.ind=T)] = 1.0
	p0[which(p1 == 0.0 & p0 == 0.0 & llr_testing > llr1_moments[1], arr.ind=T)] = 0.0

} else{ 
	# comes from llr_computation.r
	p0 = dpearson(llr_testing[,"llr"], moments=llr0_moments)
	p1 = dpearson(llr_testing[,"llr"], moments=llr1_moments)

	# for positions with both p0 and p1 == 0.0, these means that the values were extreme
	# so find the direction of the extreme value and adapt
	p1[which(p0==0.0 & p1==0.0)] = 0.0
	p0[which(p0==0.0 & p1==0.0)] = 1.0

	p1[which(p1 == 0.0 & p0 == 0.0 & llr_testing[,"llr"] > llr1_moments[1])] = 1.0
	p0[which(p1 == 0.0 & p0 == 0.0 & llr_testing[,"llr"] > llr1_moments[1])] = 0.0
}

probas = round(p1/(p0+p1), 4)

stopifnot(length(which(is.na(probas))) == 0)

cat("Probas computed\n")

#------------------------------------------------------------------------------#
# Write probabilities
#------------------------------------------------------------------------------#

if (ncol(llr_testing) == nrow(llr_testing)){ 
	output_df = matrix(probas, nrow=nrow(llr_testing), ncol=nrow(llr_testing))
	colnames(output_df) = colnames(llr_testing)
	cat("Mean proba diag:",mean(diag(output_df)),"\n")
	cat("Mean proba overall:",mean(output_df),"\n")
	out_gz = gzfile(args$probas, 'w')
	write.table(output_df, file=out_gz, row.names=F, quote=F)
	close(out_gz)
} else{
	output_df = data.frame(IID=llr_testing[,"IID"], Proba=probas)
	cat("Mean proba :",mean(output_df$Proba),"\n")
	out_gz = gzfile(args$probas, 'w')
	write.table(output_df, file=out_gz, row.names=F, quote=F)
	close(out_gz)
}

