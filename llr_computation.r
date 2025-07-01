suppressPackageStartupMessages(library(R.utils))
library(data.table)
library(argparse)
library(mvtnorm)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

# Create parser object
parser <- ArgumentParser()

# Add arguments
parser$add_argument("--pheno", help = "Input pheno data frame", required = T)
parser$add_argument("--pgs", help = "Input pgs data frame", required = T)
parser$add_argument("--r2", help="Input var explained for each phenotype", required=T)
parser$add_argument("--ce", help="Input env correlaiton", required=T)
parser$add_argument("--llr", help="Output path to LLR computed", required=T)

# Parse the args
args <- parser$parse_args()

#------------------------------------------------------------------------------#
# Import phenos, pgs, r2 and Ce
#------------------------------------------------------------------------------#
merged_pheno_df = fread(args$pheno, hea=T)
merged_pgs_df = fread(args$pgs, hea=T)
r2 = read.table(args$r2, hea=T)$r2
corr_mat_env = as.matrix(fread(args$ce))
n_pheno = length(r2)
stopifnot(nrow(merged_pgs_df$IID)== nrow(merged_pheno_df$IID))
stopifnot(length(r2) == (ncol(merged_pgs_df) - 1))
cat("Phenotypes and PGS imported\n")

#------------------------------------------------------------------------------#
# Quantile normalize phenotypes and pgs
#------------------------------------------------------------------------------#
quantile_norm = function(x){
    norm_dist = rnorm(length(x), mean=0, sd=1)
    ori_order = order(x)
    sorted_dist = x[ori_order]
    sorted_new_dist = sort(norm_dist)
    new_dist = sorted_new_dist[order(ori_order)]
    return(new_dist)
}

merged_pgs_df_scaled = apply(merged_pgs_df[,-c('IID')], 2, quantile_norm)
merged_pheno_df_scaled = apply(merged_pheno_df[,-c('IID')], 2, quantile_norm)

# debugging
#cat(paste( apply(merged_pheno_df_scaled, 2, mean), apply(merged_pheno_df_scaled,2 , sd), apply(merged_pgs_df_scaled, 2, mean) , apply(merged_pgs_df_scaled,2 , sd) ), fill=TRUE, sep='\t')

cat("Data quantile normalized", fill=TRUE)

#------------------------------------------------------------------------------#
# Run LLR
#------------------------------------------------------------------------------#

# compute differences
diff_mat = merged_pheno_df_scaled - as.matrix(merged_pgs_df_scaled)%*%diag(sqrt(r2))

# Under H1
p0_H1 = dmvnorm(merged_pheno_df_scaled,mean=rep(0,n_pheno),sigma=corr_mat_env,log = TRUE)
p1_H1 = dmvnorm(diff_mat,mean=rep(0,n_pheno),sigma=diag(sqrt(1-r2))%*%corr_mat_env%*%diag(sqrt(1-r2)),log = TRUE)
llr = p1_H1 - p0_H1
cat("llr computed\n")

#------------------------------------------------------------------------------#
# Write llrs
#------------------------------------------------------------------------------#
output_df = data.frame(IID=merged_pheno_df$IID,llr=llr) 
out_gz = gzfile(args$llr, 'w')
write.table(output_df, file=out_gz, row.names=F, quote=F)
close(out_gz)

